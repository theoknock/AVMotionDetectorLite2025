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
    @State private var baseline: Double = 0.0
    @State private var tareUIImage: UIImage? = nil
    @State private var referenceUIImage: UIImage? = nil
    @State private var scoreReferenceUIImage: UIImage? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text("AVMotionDetectorLite2025")
                .scaledToFill()
                .bold()
            
            .foregroundColor(.white)
            
            CameraPreview(session: cameraManager.session)
                .frame(maxWidth: UIScreen.main.bounds.size.width / 3, maxHeight: UIScreen.main.bounds.size.height / 3)
                .cornerRadius(12)
                .border(Color.white, width: 2)
            
            Slider(value: $threshold, in: 0...100, step: 1) {
                Text("Threshold")
                    .foregroundColor(.white)
            }
            Text(String(format: "Threshold: %.2f", threshold))
                .foregroundColor(.white)
            
            Text(String(format: "Score: %.4f", cameraManager.lastThresholdScore))
                .font(.headline)
                .foregroundColor(.white)
            
            Text(String(format: "Scene Change Score: %.4f", cameraManager.sceneChangeScore))
                .font(.headline)
                .foregroundColor(.white)
            
            Button(action: {
                isRecording.toggle()
                cameraManager.threshold = threshold
                if isRecording {
                    cameraManager.startRecording()
                } else {
                    cameraManager.stopRecording()
                }
            }) {
                Text(isRecording ? "PAUSE" : "MONITOR")
                    .padding()
                                    .frame(maxWidth: .infinity)
                    .background(isRecording ? Color.green : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            (cameraManager.lastThresholdScore > threshold ? Color.red : Color.black)
                .ignoresSafeArea()
            
            HStack {
                Button("TARE") {
                    baseline = cameraManager.lastThresholdScore
                    threshold = baseline
                    cameraManager.threshold = baseline
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("Save Frame") {
                    if let image = cameraManager.captureCurrentFrameAsUIImage() {
                        referenceUIImage = image
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Text(String(format: "Baseline: %.4f", baseline))
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            
            if let savedImage = referenceUIImage {
                Image(uiImage: savedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: UIScreen.main.bounds.size.width / 3, maxHeight: UIScreen.main.bounds.size.height / 3)
                    .border(Color.blue, width: 2)
            }
            
        }
        .padding()
        .background(Color.black.opacity(1.0))
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
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
