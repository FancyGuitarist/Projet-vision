//
//  multi.swift
//  ContinuityCam
//
//  Created by Antoine Veillette on 2024-10-23.
//  Copyright © 2024 Apple. All rights reserved.
//

import AVFoundation
import AppKit
import Cocoa
class ViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let context = CIContext()
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        guard
            let filter = CIFilter(name: "CISepiaTone"),
            let imageURL = Bundle.main.url(forResource: "my-image", withExtension: "png"),
            let ciImage = CIImage(contentsOf: imageURL)
        else { return }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(0.5, forKey: kCIInputIntensityKey)
        guard let result = filter.outputImage, let cgImage = context.createCGImage(result, from: result.extent)
        else { return }
        let destinationURL = desktopURL.appendingPathComponent("my-image.png")
        let nsImage = NSImage(cgImage: cgImage, size: ciImage.extent.size)
        if nsImage.pngWrite(to: destinationURL, options: .withoutOverwriting) {
            print("File saved")
            print(destinationURL)
        }
    }
}
extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }
    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        do {
            try pngData?.write(to: url, options: options)
            return true
        } catch {
            print(error)
            return false
        }
    }
}

class CameraViewController: NSViewController {
    
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var photoOutput: AVCapturePhotoOutput!
    var image_counter: Int = 0
    
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
            let cameraInput = try AVCaptureDeviceInput(device: AVCaptureDevice.userPreferredCamera ?? iPhoneCamera)
            print("Camera Input: \(cameraInput.device.minimumFocusDistance)")
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
        let output: Void = photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        let image = NSImage(data: imageData)
        let desktopURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
                // Get the URL to the app container's 'tmp' directory.
        let isCaptured = image?.pngWrite(to: desktopURL.appendingPathComponent("MyImage_\(image_counter).png"))
        
        // Save or process the captured image from iPhone
        print("Photo captured: \(isCaptured ?? false), #\(image_counter)")
        print(listCameraDetails())
    }
}
