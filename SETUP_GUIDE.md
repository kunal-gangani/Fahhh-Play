# Mouth Detection Flutter App

## Overview
This Flutter application showcases real-time mouth detection using face detection. The app features:

1. **Splash Screen**: A welcome screen that displays for 3 seconds before transitioning to the main app
2. **Home Page**: Real-time camera feed with mouth detection
3. **Audio Feedback**: Plays sound when the user opens their mouth
4. **State Tracking**: Audio only plays when the mouth transitions from closed to open

## Features

- 📱 Front-facing camera access
- 😐 Real-time mouth detection using ML Kit Face Detection
- 🔊 Audio playback when mouth opens
- ✨ Animated splash screen
- 🎨 Clean and intuitive UI

## Setup Instructions

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Add Audio File
The app requires an MP3 audio file placed at `assets/mouth_sound.mp3`.

**Options:**
- **Use a pre-made beep sound**: Download from a free sound library like:
  - [Freesound.org](https://freesound.org/) - search for "beep" or "alert"
  - [Zapsplat](https://www.zapsplat.com/)
  - [Pixabay Sounds](https://pixabay.com/sound-effects/)

- **Generate your own**: Use a tool like Audacity to create a simple beep sound

- **Or download a sample beep**: A simple beep MP3 file (you can find many online)

Once you have the audio file:
1. Place it in the `assets/` directory
2. Name it `mouth_sound.mp3`

### 3. Platform-Specific Setup

#### Android
1. Open `android/app/build.gradle`
2. Ensure `compileSdk` is at least 34
3. Add camera permissions in `AndroidManifest.xml` (should be auto-handled)

#### iOS
1. Open `ios/Runner.xcworkspace` in Xcode
2. Add Camera and Microphone permissions in `Info.plist`:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>We need access to your camera to detect mouth movements</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>We need microphone access for the app</string>
   ```

### 4. Run the App
```bash
flutter run
```

## How to Use

1. **Launch the app** - You'll see the splash screen for 3 seconds
2. **Grant camera permission** - Allow the app to access your front camera
3. **Position your face** - Make sure your face is visible in the camera feed
4. **Open your mouth** - The app will:
   - Detect when your mouth opens (indicated by the status indicator)
   - Play the audio file
   - Audio will play each time you open your mouth after closing it

## Technical Details

### Dependencies
- **camera**: Access device camera
- **google_mlkit_face_detection**: Face and mouth detection
- **just_audio**: Audio playback
- **permission_handler**: Runtime permissions

### How Mouth Detection Works
The app uses Google ML Kit's Face Detection to:
1. Detect faces in the camera frame
2. Extract mouth landmarks (top, bottom, left, right)
3. Calculate the ratio of mouth height to width
4. Determine if the mouth is open based on this ratio

### State Management
- Audio plays on the **first mouth opening** and each **transition from closed to open**
- Once the mouth closes, the next opening will trigger audio again
- This prevents continuous playback while the mouth stays open

## Troubleshooting

### No audio playing
- Ensure the audio file is placed correctly at `assets/mouth_sound.mp3`
- Check that the volume is not muted on your device
- Try running `flutter clean` and `flutter pub get` again

### Camera not working
- Check that camera permissions are granted
- Ensure the device has a front-facing camera
- Try running the app on a different device

### Mouth detection not accurate
- Ensure adequate lighting
- Position your face directly towards the camera
- Keep your face within the recognized frame

## Customization

### Change the Detection Threshold
Edit `_detectMouthOpen()` in `lib/screens/home_page.dart`:
```dart
// Adjust this value (currently 0.4) to make detection more/less sensitive
return mouthHeight > (mouthWidth * 0.4);
```

### Change Audio File
Simply replace `mouth_sound.mp3` with another audio file with the same name.

### Modify Detection Interval
In `lib/screens/home_page.dart`, change the Duration:
```dart
Timer.periodic(const Duration(milliseconds: 500), (timer) async {
  // Reduce 500 for more frequent checks, increase for less frequent
});
```

## Notes
- The app captures images briefly for processing but does not store them
- Face detection happens in real-time on the device (no cloud processing)
- The detection works best in well-lit environments
- Wear glasses, beards, or other facial accessories shouldn't affect detection

---

**Enjoy the app! 🎉**
