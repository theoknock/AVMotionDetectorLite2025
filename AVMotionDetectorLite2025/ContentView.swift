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
    @State private var sceneChangeThreshold: Double = 0.5
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
            
            ZStack(alignment: .topTrailing) {
                CameraPreview(session: cameraManager.session)
                    .frame(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.width)
                    .cornerRadius(12)
                    .border(Color.white, width: 2)
                
                if let savedImage = referenceUIImage {
                    Image(uiImage: savedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.size.width / 3, height: UIScreen.main.bounds.size.width / 3)
                        .clipped()
                        .border(Color.blue, width: 2)
                        .padding(8) // optional: gives some margin from the corner
                }
            }
            
            ZStack(alignment: .center) {
                Slider(value: $threshold, in: 0...100, step: 1)
//                    .padding(.top, 20) // Make space for the overlay text
                
                Text(String(format: "%.0f", threshold))
                    .font(.title2)
                    .foregroundColor(.orange)
                    .bold()
                    .shadow(radius: 1.5)
            }
            
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
            
            //                Text(String(format: "%.0f", threshold))
            //                    .font(.title2)
            //                    .foregroundColor(.orange)
            //                    .bold()
            //                    .shadow(radius: 1.5)
            //                    .frame(width: .infinity)
            
            
            Slider(value: $sceneChangeThreshold, in: 0...100, step: 1) {
                Text("Scene Change Threshold")
                    .foregroundColor(.white)
            }
            Text(String(format: "Scene Change Threshold: %.2f", sceneChangeThreshold))
                .foregroundColor(.white)
            
            
            
            Button("TARE (Scene Change)") {
                sceneChangeThreshold = cameraManager.sceneChangeScore
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .background(Color.black.opacity(1.0))
        
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
        
        //            HStack {
        //                Button("TARE") {
        //                    baseline = cameraManager.lastThresholdScore
        //                    threshold = baseline
        //                    cameraManager.threshold = baseline
        //                }
        //                .padding(.horizontal)
        //                .padding(.vertical, 8)
        //                .background(Color.gray)
        //                .foregroundColor(.white)
        //                .cornerRadius(10)
        
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
        //
        //                Text(String(format: "Baseline: %.4f", baseline))
        //                    .font(.subheadline)
        //                    .foregroundColor(.white)
        //            }
        //
        
        
    }
    //        .padding()
    //        .background(Color.black.opacity(1.0))
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
