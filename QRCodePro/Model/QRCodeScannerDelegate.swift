//
//  QRCodeScannerDelegate.swift
//  QRCodePro
//
//  Created by Quang Bao on 18/05/2023.
//

import Foundation
import SwiftUI
import AVKit

class QRScannerDelegate: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    
    @Published var scannerCode: String?
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metaObject = metadataObjects.first {
            guard let readableObject = metaObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let code = readableObject.stringValue else { return }
            print("DEBUG: Result code: " + code)
            scannerCode = code
        }
    }
}
