//
//  ScannerView.swift
//  QRCodePro
//
//  Created by Quang Bao on 17/05/2023.
//

import SwiftUI
import AVKit

struct ScannerView: View {
    
    /// ScannerViewModel
    @StateObject var viewModel = ScannerViewModel()
    
    /// Camera QR Output Delegate
    @StateObject private var qrDelegate = QRScannerDelegate()
    @State var scannerCode: String = ""
    
    /// Error Properties
    @Environment(\.openURL) private var openURL
    
    
    //    /// QR Code Scanner Properties
    //    @State private var isScanning: Bool = false
    //    @State private var session: AVCaptureSession = .init()
    //    @State private var cameraPermission: CameraPermission = .authorized
    //
    //    /// QR Scanner AV Output
    //    @State private var qrOutput: AVCaptureMetadataOutput = .init()
    
    //    /// Error Properties
    //    @State private var errorMessage: String = ""
    //    @State private var isShowError: Bool = false
    //    @Environment(\.openURL) private var openURL
    
    //    /// Camera QR Output Delegate
    //    @StateObject private var qrDelegate = QRScannerDelegate()
    //    @State var scannerCode: String = ""
    
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
                .foregroundColor(Color.secondary)
                .padding(.top, 20)
            
            Text("Scaning will start automatically")
            //                .font(.body)
                .font(.callout)
                .foregroundColor(.gray)
                .padding(.top, 20)
            
            Text(scannerCode)
                .font(.largeTitle)
                .foregroundColor(.yellow)
            
            Spacer(minLength: 15)
            
            /// Scanner
            GeometryReader {
                
                let size = $0.size
                
                ZStack(alignment: .top) {
                    
                    CameraView(frameSize: CGSize(width: size.width, height: size.width), session: $viewModel.session)
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
                            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: viewModel.isScanning ? 10 : -10)
                            .offset(y: viewModel.isScanning ? size.width : 0)
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
                if !viewModel.session.isRunning && viewModel.cameraPermission == .authorized {
                    viewModel.reActivateCamera()
                    viewModel.activateScannerAnimation()
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
            viewModel.checkCameraPermission(qrDelegate: qrDelegate)
        })
        .onChange(of: qrDelegate.scannerCode, perform: { newValue in
            if let scannerCode = newValue {
                self.scannerCode = scannerCode
                /// When the first code scan is available, immediately stop the camera
                viewModel.session.stopRunning()
                /// Stopping Scanner Animation
                viewModel.deActivateScannerAnimation()
                /// Clear the Data on Delegate
                qrDelegate.scannerCode = nil
            }
        })
        .alert(viewModel.errorMessage, isPresented: $viewModel.isShowError) {
            /// Showing Setting's Button, if Permission is Denied
            if viewModel.cameraPermission == .denied {
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
}

struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerView()
    }
}
