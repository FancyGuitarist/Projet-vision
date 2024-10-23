//
//  multi.swift
//  ContinuityCam
//
//  Created by Antoine Veillette on 2024-10-23.
//  Copyright © 2024 Apple. All rights reserved.
//

import AVFoundation
import AppKit

class CameraViewController: NSViewController {
    
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var photoOutput: AVCapturePhotoOutput!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        // Discover and select the iPhone camera via Continuity Camera
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.externalUnknown],
                                                                mediaType: .video,
                                                                position: .unspecified)
        
        guard let iPhoneCamera = discoverySession.devices.first(where: { $0.localizedName.contains("iPhone") }) else {
            print("iPhone camera not found")
            return
        }
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: iPhoneCamera)
            if captureSession.canAddInput(cameraInput) {
                captureSession.addInput(cameraInput)
            }
            
            // Configure the photo output
            photoOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            
            // Add a preview layer to the macOS app window to display the camera feed
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer.videoGravity = .resizeAspectFill
            videoPreviewLayer.frame = view.bounds
            view.layer?.addSublayer(videoPreviewLayer)
            
            captureSession.startRunning()
            
        } catch {
            print("Error setting up iPhone camera: \(error)")
        }
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        let image = NSImage(data: imageData)
        
        // Save or process the captured image from iPhone
        print("Photo captured successfully")
    }
}
