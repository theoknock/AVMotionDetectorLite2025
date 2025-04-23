//
//  CameraManager.swift
//  AVMotionDetectorLite2025
//
//  Created by Xcode Developer on 4/23/25.
//

import AVFoundation

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()

    private var previousPixelBuffer: CVPixelBuffer?
    @Published var motionDetected = false
    @Published var lastThresholdScore: Double = 0.0
    var threshold: Double = 0.5
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

        if let previous = previousPixelBuffer {
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
            for x in stride(from: 0, to: bytesPerRow, by: 4) {
                let index = y * bytesPerRow + x
                let luma1 = 0.299 * Double(ptr1[index + 2]) + 0.587 * Double(ptr1[index + 1]) + 0.114 * Double(ptr1[index])
                let luma2 = 0.299 * Double(ptr2[index + 2]) + 0.587 * Double(ptr2[index + 1]) + 0.114 * Double(ptr2[index])
                diffSum += abs(luma1 - luma2)
            }
        }

        let maxDiff = Double(height * (bytesPerRow / 4)) * 255.0
        return diffSum / maxDiff
    }

    func startRecording() {
        isRecording = true
        previousPixelBuffer = nil
    }

    func stopRecording() {
        isRecording = false
        previousPixelBuffer = nil
    }
}
