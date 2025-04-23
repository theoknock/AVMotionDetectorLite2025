//
//  ContentView.swift
//  AVMotionDetectorLite2025
//
//  Created by Xcode Developer on 4/22/25.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var isRecording = false
    @State private var threshold: Double = 0.5

    var body: some View {
        VStack(spacing: 20) {
            Text("Frame Differencing")
                .font(.largeTitle)
                .bold()

            CameraPreview(session: cameraManager.session)
                .frame(height: 300)
                .cornerRadius(12)
                .border(Color.white, width: 2)

            Slider(value: $threshold, in: 0...1, step: 0.0001) {
                Text("Threshold")
            }
            Text(String(format: "Threshold: %.2f", threshold))

            Text(String(format: "Score: %.4f", cameraManager.lastThresholdScore))
                .font(.headline)

            Button(action: {
                isRecording.toggle()
                cameraManager.threshold = threshold
                if isRecording {
                    cameraManager.startRecording()
                } else {
                    cameraManager.stopRecording()
                }
            }) {
                Text(isRecording ? "Stop" : "MONITOR")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isRecording ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .alert("Motion Detected!", isPresented: $cameraManager.motionDetected) {
                Button("OK", role: .cancel) { }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

struct CameraPreview: UIViewRepresentable {
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }

    let session: AVCaptureSession

    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: VideoPreviewView, context: Context) {}
}
