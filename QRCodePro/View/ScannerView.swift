//
//  ScannerView.swift
//  QRCodePro
//
//  Created by Quang Bao on 17/05/2023.
//

import SwiftUI
import AVKit

struct ScannerView: View {
    
    /// QR Code Scanner Properties
    @State private var isScanning: Bool = false
    @State private var session: AVCaptureSession = .init()
    @State private var cameraPermission: CameraPermission = .authorized
    
    /// QR Scanner AV Output
    @State private var qrOutput: AVCaptureMetadataOutput = .init()
    
    /// Error Properties
    @State private var errorMessage: String = ""
    @State private var isShowError: Bool = false
    @Environment(\.openURL) private var openURL
    
    /// Camera QR Output Delegate
    @StateObject private var qrDelegate = QRScannerDelegate()
    @State var scannerCode: String = ""
    
    var body: some View {
        VStack(spacing: 8) {
            Button {
                
            } label: {
                Image(systemName: "xmark")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Place the QRCode inside the area")
                .font(.headline)
                .foregroundColor(.black.opacity(0.8))
                .padding(.top, 20)
            
            Text("Scaning will start automatically")
//                .font(.body)
                .font(.callout)
                .foregroundColor(.gray)
            
            Spacer(minLength: 15)
            
            /// Scanner
            GeometryReader {
                
                let size = $0.size
                
                ZStack(alignment: .top) {
                    
                    CameraView(frameSize: CGSize(width: size.width, height: size.width), session: $session)
                    /// Making it little smaller
                        .scaleEffect(0.97)
                    
                    ForEach(0..<4) { index in
                        let rotation = Double(index * 90)
                        
                        RoundedRectangle(cornerRadius: 2, style: .circular)
                        /// Trimming to get Scanner like Edges
                            .trim(from: 0.61, to: 0.64)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 5,
                                                                   lineCap: .round,
                                                                   lineJoin: .round))
                            .rotationEffect(Angle.degrees(rotation))
                    }
                    .overlay(alignment: .top, content: {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.green)
                            .frame(height: 3)
                            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: isScanning ? 10 : -10)
                            .offset(y: isScanning ? size.width : 0)
                    })
                }
                /// Square Shape
                .frame(width: size.width, height: size.width)
                /// Make it Center
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 45)
            
            Spacer(minLength: 15)
            
            Button {
                if !session.isRunning && cameraPermission == .authorized {
                    reActivateCamera()
                    activateScannerAnimation()
                }
            } label: {
                Image(systemName: "qrcode.viewfinder")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            }

            Spacer(minLength: 45)
        }
        .padding(15)
        /// Checnking Camera Permission when the View is visible
        .onAppear(perform: {
            checkCameraPermission()
        })
        .onChange(of: qrDelegate.scannerCode, perform: { newValue in
            if let scannerCode = newValue {
                self.scannerCode = scannerCode
                /// When the first code scan is available, immediately stop the camera
                session.stopRunning()
                /// Stopping Scanner Animation
                deActivateScannerAnimation()
                /// Clear the Data on Delegate
                qrDelegate.scannerCode = nil
            }
        })
        .alert(errorMessage, isPresented: $isShowError) {
            /// Showing Setting's Button, if Permission is Denied
            if cameraPermission == .denied {
                Button {
                    let settingString = UIApplication.openSettingsURLString
                    if let settingURL = URL(string: settingString) {
                        /// Opening App's Setting, Using openURL SwiftUI API
                        openURL(settingURL)
                    }
                } label: {
                    Text("Setting")
                }

                /// Along with Cancel Button
                Button("Cancel", role: .cancel) {
                    /// Do nothing
                }
            }
        }
    }
    
    /// Re-Activate Camera
    func reActivateCamera() {
        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }
    }
    
    /// Activating Sanner animation method
    func activateScannerAnimation() {
        /// Add delay for each revesal and repeat
        withAnimation(.easeInOut(duration: 1).delay(0.15).repeatForever()) {
            isScanning = true
        }
    }
    
    /// de-Activating Sanner animation method
    func deActivateScannerAnimation() {
        /// Add delay for each revesal and repeat
        withAnimation(.easeInOut(duration: 0.5)) {
            isScanning = false
        }
    }
    
    /// Checking Camera Permission
    func checkCameraPermission() {
        Task {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
                
            case .notDetermined:
                ///Request Camera Access
                if await AVCaptureDevice.requestAccess(for: .video) {
                    ///Permission Granted
                    cameraPermission = .authorized
                    if session.inputs.isEmpty {
                        /// New setup
                        setupCamera()
                    } else {
                        /// Already Existing One
                        session.startRunning()
                    }
                } else {
                    /// Permission Denied
                    cameraPermission = .denied
                    /// Present a Error Message
                    presentError("Please Provide Access Permission to the Camera for Scanning Codes")
                }
            case .restricted:
                cameraPermission = .restricted
                presentError("Please Provide Access Permission to the Camera for Scanning Codes")
            case .denied:
                cameraPermission = .denied
                presentError("Please Provide Access Permission to the Camera for Scanning Codes")
            case .authorized:
                cameraPermission = .authorized
                setupCamera()
            @unknown default:
                break
            }
        }
    }
    
    /// Setting Up Camera
    func setupCamera() {
        do {
            /// Finding Back Camera
            guard let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first else {
                presentError("Unknow Device Error")
                return
            }
            
            /// Camera Input
            let input = try AVCaptureDeviceInput(device: device)
            /// For Extra Saftey
            /// Checking Where input & output can be added to the session
            guard session.canAddInput(input), session.canAddOutput(qrOutput) else {
                presentError("Unknow Input/Output Error")
                return
            }
            
            /// Adding Input & Output to Camera Session
            session.beginConfiguration()
            session.addInput(input)
            session.addOutput(qrOutput)
            
            /// Setting Output config to read QR Codes
            qrOutput.metadataObjectTypes = [.qr]
            
            /// Adding Delegate to Retreive the Fetched QR Code from Camera
            qrOutput.setMetadataObjectsDelegate(qrDelegate, queue: .main)
            session.commitConfiguration()
            
            /// Note Session must be started on Background thread
            /// Recheck this command line
            DispatchQueue.global(qos: .background).async {
                session.startRunning()
            }
            
            activateScannerAnimation()
        } catch {
            
        }
    }
    
    /// Presenting Error
    func presentError(_ message: String) {
        self.errorMessage = message
        isShowError = true
    }
}

struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerView()
    }
}
