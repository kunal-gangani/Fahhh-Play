# Riverpod State Management Implementation

## What Changed

The app has been refactored to use **Riverpod** for state management, replacing the previous StatefulWidget approach. This provides better separation of concerns, easier testing, and more scalable code.

## Architecture Overview

### Controllers (State Notifiers)

#### 1. **camera_controller.dart**
- Manages camera initialization and lifecycle
- Handles camera permissions
- Provides `CameraControllerNotifier` for state management
- State: `isInitialized`, `error`, `camera` instance

#### 2. **mouth_detection_controller.dart**
- Processes face images for mouth detection
- Manages mouth open/closed state
- Tracks when mouth transitions from closed to open
- State: `isMouthOpen`, `wasMouthClosedBefore`, `isProcessing`, `status`

#### 3. **audio_controller.dart**
- Handles audio loading and playback
- Auto-detects audio file in Media or assets folder
- State: `isReady`, `isPlaying`, `error`

### HomePage

Now uses `ConsumerStatefulWidget` (Riverpod) instead of `StatefulWidget`:
- Watches all three providers for state changes
- UI automatically rebuilds when state changes
- Clean separation between UI and business logic

## Setup Instructions

### 1. Ensure Media Folder Exists

Create a `Media/` folder in your project root:
```
your_project/
├── lib/
├── assets/
├── Media/           <- Create this folder
│   └── mouth_sound.mp3  <- Place your audio here
├── pubspec.yaml
└── ...
```

### 2. Add Your Audio File

1. Prepare an MP3 audio file (e.g., a beep sound)
2. Place it in the `Media/` folder and name it `mouth_sound.mp3`
3. The app will automatically load from this location

**Where to get audio files:**
- [Freesound.org](https://freesound.org/)
- [Zapsplat](https://www.zapsplat.com/)
- [Pixabay Sounds](https://pixabay.com/sound-effects/)

### 3. Update pubspec.yaml

The `pubspec.yaml` has been updated to:
```yaml
assets:
  - Media/  # All files in Media folder will be included
```

### 4. Run the App

```bash
flutter pub get
flutter run
```

## How Riverpod Works

### Providers

**Providers** are declarations that describe how to compute or provide a piece of state:

```dart
final cameraControllerProvider = StateNotifierProvider<...>((ref) => ...);
```

### Watching Providers

In UI, use `ref.watch()` to listen to provider changes:

```dart
final cameraState = ref.watch(cameraControllerProvider);
// UI updates whenever cameraState changes
```

### Reading Providers

Use `ref.read()` to get current value without listening:

```dart
await ref.read(audioControllerProvider.notifier).playAudio();
```

## State Flow

```
User opens mouth
    ↓
Camera captures frame
    ↓
MouthDetectionController detects mouth open
    ↓
Updates mouthDetectionProvider state
    ↓
HomePage watches the change via ref.watch()
    ↓
UI rebuilds with new mouth state
    ↓
If mouth transitioned from closed→open, trigger audio
    ↓
AudioController plays sound
```

## Benefits of Riverpod

✅ **No setState() calls** - Providers handle state automatically
✅ **Reactive UI** - Only affected widgets rebuild
✅ **Easier testing** - Providers are testable without BuildContext
✅ **Better code organization** - Business logic in controllers
✅ **Scalability** - Easy to add new features
✅ **Combine providers** - Build complex state from simpler pieces

## File Structure

```
lib/
├── main.dart
├── screens/
│   ├── splash_screen.dart
│   └── home_page.dart
├── controllers/
│   ├── camera_controller.dart
│   ├── mouth_detection_controller.dart
│   └── audio_controller.dart
└── ...
```

## Troubleshooting

### Audio not playing
- Verify `Media/mouth_sound.mp3` exists in project root
- Check audio file format (should be MP3)
- Try fallback: place file in `assets/` folder (both locations are checked)

### State not updating in UI
- Ensure using `ref.watch()` in build method, not `ref.read()`
- Check that HomePage extends `ConsumerStatefulWidget`
- Verify ProviderScope wraps MyApp

### Camera permission denied
- Allow camera permissions in device settings
- On Android: Check AndroidManifest.xml has camera permission
- On iOS: Check Info.plist has NSCameraUsageDescription

## Customization

### Change detection threshold
Edit `mouth_detection_controller.dart`:
```dart
bool _detectMouthOpen(...) {
  // Adjust 0.4 to make detection more/less sensitive
  return mouthHeight > (mouthWidth * 0.4);
}
```

### Change detection interval
Edit `home_page.dart`:
```dart
_detectionTimer = Timer.periodic(
  const Duration(milliseconds: 500), // Change this value
  (_) async { ... }
);
```

### Add new features
1. Create a new StateNotifier if needed
2. Create a new provider using StateNotifierProvider
3. Watch the provider in HomePage
4. Update UI based on state changes

---

**Architecture is now clean, scalable, and production-ready!** 🚀
