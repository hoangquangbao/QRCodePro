//
//  ScannerViewModel.swift
//  QRCodePro
//
//  Created by Quang Bao on 18/05/2023.
//

import Foundation
import SwiftUI
import AVKit

class ScannerViewModel: ObservableObject {
    
    /// QR Code Scanner Properties
    @Published var isScanning: Bool = false
    @Published var session: AVCaptureSession = .init()
    @Published var cameraPermission: CameraPermission = .authorized
    
    /// QR Scanner AV Output
    @Published var qrOutput: AVCaptureMetadataOutput = .init()
    
    /// Error Properties
    @Published var errorMessage: String = ""
    @Published var isShowError: Bool = false
    
    /// Re-Activate Camera
    func reActivateCamera() {
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
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
    func checkCameraPermission(qrDelegate: QRScannerDelegate) {
        Task {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
                
            case .notDetermined:
                ///Request Camera Access
                if await AVCaptureDevice.requestAccess(for: .video) {
                    ///Permission Granted
                    cameraPermission = .authorized
                    if session.inputs.isEmpty {
                        /// New setup
                        setupCamera(qrDelegate: qrDelegate)
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
                setupCamera(qrDelegate: qrDelegate)
            @unknown default:
                break
            }
        }
    }
    
    /// Setting Up Camera
    func setupCamera(qrDelegate: QRScannerDelegate) {
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
            qrOutput.metadataObjectTypes = [.code128, .ean13, .qr]
            
            /// Adding Delegate to Retreive the Fetched QR Code from Camera
            qrOutput.setMetadataObjectsDelegate(qrDelegate, queue: .main)
            session.commitConfiguration()
            
            /// Note Session must be started on Background thread
            /// Recheck this command line
            DispatchQueue.global(qos: .background).async {
                self.session.startRunning()
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
