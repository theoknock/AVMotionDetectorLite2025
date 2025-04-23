//
//  CameraManager.swift
//  AVMotionDetectorLite2025
//
//  Created by Xcode Developer on 4/23/25.
//

import AVFoundation
import CoreImage
import UIKit

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()

    private var previousPixelBuffer: CVPixelBuffer?
    private var originalReferencePixelBuffer: CVPixelBuffer?
    private var tareCapturePixelBuffer: CVPixelBuffer?
    @Published var motionDetected = false
    @Published var lastThresholdScore: Double = 0.0
    @Published var tareCaptureImage: CGImage?
    var threshold: Double = 0.5
    var baseline: Double = 0.0
    var isRecording = false

    override init() {
        super.init()
        configure()
        start()
    }

    private func configure() {
        session.beginConfiguration()
        guard
            let device = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else { return }

        session.addInput(input)

        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        videoOutput.videoSettings = [
            (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
        ]
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        session.commitConfiguration()
    }

    func start() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    func stop() {
        session.stopRunning()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isRecording,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        if let previous = previousPixelBuffer,
           let original = originalReferencePixelBuffer {
            let score: Double = calculateLuminanceDifference(between: original, and: previous)
//            let diff2: Double = calculateLuminanceDifference(between: previous, and: pixelBuffer)
//            let diff3 = calculateLuminanceDifference(between: original, and: pixelBuffer)
//            let score: Double = (diff1 + diff2) / 2.0
            
//            if pixelBuffer == original {
//                tareCapturePixelBuffer = pixelBuffer
//                getTareCaptureUIImage()
//            }

            DispatchQueue.main.async {
                self.lastThresholdScore = score
                self.motionDetected = score > self.threshold
            }
        } else if let previous = previousPixelBuffer {
            let diff = calculateLuminanceDifference(between: previous, and: pixelBuffer)
            DispatchQueue.main.async {
                self.lastThresholdScore = diff
                self.motionDetected = diff > self.threshold
            }
        }

        previousPixelBuffer = pixelBuffer
    }

    private func calculateLuminanceDifference(between first: CVPixelBuffer, and second: CVPixelBuffer) -> Double {
        CVPixelBufferLockBaseAddress(first, .readOnly)
        CVPixelBufferLockBaseAddress(second, .readOnly)

        defer {
            CVPixelBufferUnlockBaseAddress(first, .readOnly)
            CVPixelBufferUnlockBaseAddress(second, .readOnly)
        }

        let width = CVPixelBufferGetWidth(first)
        let height = CVPixelBufferGetHeight(first)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(first)

        guard width == CVPixelBufferGetWidth(second),
              height == CVPixelBufferGetHeight(second),
              bytesPerRow == CVPixelBufferGetBytesPerRow(second),
              let baseAddress1 = CVPixelBufferGetBaseAddress(first),
              let baseAddress2 = CVPixelBufferGetBaseAddress(second)
        else { return 0 }

        let ptr1 = baseAddress1.assumingMemoryBound(to: UInt8.self)
        let ptr2 = baseAddress2.assumingMemoryBound(to: UInt8.self)
        
        var diffSum: Double = 0
        for y in 0..<height {
            for x in 0..<width {
                let index = y * bytesPerRow + x * 4
                let luma1: Double = 0.299 * Double(ptr1[index + 2]) + 0.587 * Double(ptr1[index + 1]) + 0.114 * Double(ptr1[index])
                let luma2: Double = 0.299 * Double(ptr2[index + 2]) + 0.587 * Double(ptr2[index + 1]) + 0.114 * Double(ptr2[index])
                diffSum += (luma2 - luma1)
            }
        }
        
        let diffAvg: Double = abs(diffSum / Double(width * height))
        
        return abs(diffAvg)

//        var diffSum: Double = 0
//        for y in 0..<height {
//            for x in 0..<width {
//                let index = y * bytesPerRow + x * 4
//                let luma1 = 0.299 * Double(ptr1[index + 2]) + 0.587 * Double(ptr1[index + 1]) + 0.114 * Double(ptr1[index])
//                let luma2 = 0.299 * Double(ptr2[index + 2]) + 0.587 * Double(ptr2[index + 1]) + 0.114 * Double(ptr2[index])
//                diffSum += abs(luma2 - luma1)
//            }
//        }

//        let pixelCount = Double(width * height)
//        let average = diffSum / (pixelCount * 255.0)
//        let adjusted = average - baseline
//        return adjusted > 0 ? adjusted : 0
    }

    func startRecording() {
        isRecording = true
        previousPixelBuffer = nil
    }

    func stopRecording() {
        isRecording = false
        previousPixelBuffer = nil
    }

    func setOriginalReferenceFrame(from pixelBuffer: CVPixelBuffer) {
        originalReferencePixelBuffer = pixelBuffer
        if let oldest = previousPixelBuffer {
            tareCapturePixelBuffer = oldest
            tareCaptureImage = convertToCGImage(from: oldest)
        }
    }

    private func convertToCGImage(from pixelBuffer: CVPixelBuffer) -> CGImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        return context.createCGImage(ciImage, from: ciImage.extent)
    }

    func clearOriginalReferenceFrame() {
        originalReferencePixelBuffer = nil
    }

    func clearTareCaptureFrame() {
        tareCapturePixelBuffer = nil
        tareCaptureImage = nil
    }
    
    func getTareCaptureUIImage() -> UIImage? {
        guard let buffer = tareCapturePixelBuffer else { return nil }
        let ciImage = CIImage(cvPixelBuffer: buffer)
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
    
    func getOriginalReferenceUIImage() -> UIImage? {
        guard let buffer = originalReferencePixelBuffer else { return nil }
        let ciImage = CIImage(cvPixelBuffer: buffer)
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
    
    func getScoreReferenceUIImage() -> UIImage? {
        return getTareCaptureUIImage()
    }
}
