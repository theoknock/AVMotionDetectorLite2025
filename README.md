# 📸 AVMotionDetector 2025

**Next-gen Motion Detection and Scene Monitoring in Real Time**  

AVMotionDetector2025 is a Swift-powered iOS app that combines traditional **motion detection** with a powerful new feature: **scene change monitoring**. Not only can it detect moving intruders, but it can also alert you when something appears—or disappears—without moving at all.

![AVMotionDetector2025Icon-small](https://github.com/user-attachments/assets/9286dfda-bf43-43a3-aa11-f29c1f5bf9bc)

---

## 🔍 Key Features

- **🎥 Live Video Feed** from your device’s camera  
- **🕵️ Motion Detection:** Detects movement between frames with luminance-based frame differencing  
- **🖼️ Scene Monitoring:** Captures a reference frame on tap to track subtle, non-moving changes to the environment  
- **🧠 Dual Scoring System:**  
  - `Score`: Motion detected by comparing two consecutive frames  
  - `Scene Change Score`: Environmental changes compared against a saved reference frame  
- **🧪 Visual Debug UI:** Real-time display of threshold sliders, scores, and reference images  
- **📸 "Save Frame" Button:** Freezes a moment for scene comparison, creating a stable baseline for evaluation  

---

## 🚀 How It Works

1. **Tap TARE** to baseline current video noise.  
2. **Tap Save Frame** to store a snapshot of your environment.  
3. **Monitor both movement and scene alterations**—like a bag mysteriously appearing on a bench.

---

## 🛠️ Tech Stack

- Swift (UIKit / AVFoundation)  
- Real-time pixel buffer processing  
- Grayscale luminance differencing  
- Scene comparison using user-defined reference

---

## 🧱 Coming Soon

- Export detected scenes as snapshots  
- Adjustable sensitivity presets  
- Push notifications on motion/scene trigger  
- iOS and macOS Catalyst dual deployment  

---

## 🤖 Built For

Security use-cases, art installations, wildlife monitoring, or anyone curious about what’s *really* changing in their environment—even when nothing appears to move.
