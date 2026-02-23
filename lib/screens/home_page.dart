import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart' as cam;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/audio_controller.dart';
import '../controllers/camera_controller.dart' as cam_controller;
import '../controllers/mouth_detection_controller.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late Timer _detectionTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  void _initialize() async {
    // Initialize camera
    await ref
        .read(cam_controller.cameraControllerProvider.notifier)
        .initialize();

    // Start mouth detection loop
    _startMouthDetection();
  }

  void _startMouthDetection() {
    _detectionTimer =
        Timer.periodic(const Duration(milliseconds: 500), (_) async {
      final cameraState = ref.read(cam_controller.cameraControllerProvider);
      final mouthState = ref.read(mouthDetectionProvider);
      final audioState = ref.read(audioControllerProvider);

      if (!cameraState.isInitialized || cameraState.camera == null) return;
      if (mouthState.isProcessing) return;

      try {
        final image = await cameraState.camera!.takePicture();
        final imageFile = File(image.path);

        // Process face image
        await ref
            .read(mouthDetectionProvider.notifier)
            .processFaceImage(imageFile);

        // Check if we should play audio
        final updatedMouthState = ref.read(mouthDetectionProvider);
        if (updatedMouthState.isMouthOpen &&
            updatedMouthState.wasMouthClosedBefore &&
            audioState.isReady) {
          await ref.read(audioControllerProvider.notifier).playAudio();
        }
      } catch (e) {
        print('Detection error: $e');
      }
    });
  }

  @override
  void dispose() {
    _detectionTimer.cancel();
    ref.read(cam_controller.cameraControllerProvider.notifier).dispose();
    ref.read(audioControllerProvider.notifier).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cam_controller.cameraControllerProvider);
    final mouthState = ref.watch(mouthDetectionProvider);
    final audioState = ref.watch(audioControllerProvider);

    if (!cameraState.isInitialized || cameraState.camera == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mouth Detection'),
          backgroundColor: const Color(0xFF6200EE),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                cameraState.error ?? 'Initializing camera...',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mouth Detection'),
        backgroundColor: const Color(0xFF6200EE),
      ),
      body: Stack(
        children: [
          // Camera preview
          cam.CameraPreview(cameraState.camera!.controller),

          // Overlay with instructions
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const Text(
                        'Open Your Mouth',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        mouthState.isMouthOpen
                            ? '👄 Mouth Open'
                            : '😐 Mouth Closed',
                        style: TextStyle(
                          fontSize: 18,
                          color: mouthState.isMouthOpen
                              ? Colors.greenAccent
                              : Colors.grey,
                        ),
                      ),
                      if (audioState.isPlaying)
                        Column(
                          children: [
                            const SizedBox(height: 15),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.orangeAccent,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Playing Audio...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orangeAccent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Status indicator at top
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: mouthState.isMouthOpen ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                mouthState.isMouthOpen ? Icons.check : Icons.close,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),

          // Error message if audio failed to load
          if (audioState.error != null)
            Positioned(
              top: 80,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  audioState.error!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
