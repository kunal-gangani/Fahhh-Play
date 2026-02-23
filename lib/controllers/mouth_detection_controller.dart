import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

final mouthDetectionProvider =
    StateNotifierProvider<MouthDetectionNotifier, MouthDetectionState>(
  (ref) => MouthDetectionNotifier(),
);

class MouthDetectionState {
  final bool isMouthOpen;
  final bool wasMouthClosedBefore;
  final bool isProcessing;
  final String status;

  MouthDetectionState({
    this.isMouthOpen = false,
    this.wasMouthClosedBefore = false,
    this.isProcessing = false,
    this.status = 'Initializing...',
  });

  MouthDetectionState copyWith({
    bool? isMouthOpen,
    bool? wasMouthClosedBefore,
    bool? isProcessing,
    String? status,
  }) {
    return MouthDetectionState(
      isMouthOpen: isMouthOpen ?? this.isMouthOpen,
      wasMouthClosedBefore: wasMouthClosedBefore ?? this.wasMouthClosedBefore,
      isProcessing: isProcessing ?? this.isProcessing,
      status: status ?? this.status,
    );
  }
}

class MouthDetectionNotifier extends StateNotifier<MouthDetectionState> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
    ),
  );

  MouthDetectionNotifier() : super(MouthDetectionState());

  Future<void> processFaceImage(File imageFile) async {
    if (state.isProcessing) return;

    try {
      state = state.copyWith(isProcessing: true);

      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        final face = faces.first;
        final landmarks = face.landmarks;

        final isMouthOpen = _detectMouthOpen(landmarks);

        // Update state based on mouth status
        if (!state.isMouthOpen && isMouthOpen && state.wasMouthClosedBefore) {
          // Mouth opened after being closed
          state = state.copyWith(
            isMouthOpen: true,
            status: 'Mouth Open - Audio Playing!',
          );
        } else if (state.isMouthOpen && !isMouthOpen) {
          // Mouth closed
          state = state.copyWith(
            isMouthOpen: false,
            wasMouthClosedBefore: true,
            status: 'Mouth Closed',
          );
        } else if (!state.isMouthOpen &&
            isMouthOpen &&
            !state.wasMouthClosedBefore) {
          // First time mouth opens
          state = state.copyWith(
            isMouthOpen: true,
            wasMouthClosedBefore: false,
            status: 'Mouth Open - Audio Playing!',
          );
        }
      }

      state = state.copyWith(isProcessing: false);
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        status: 'Detection error: $e',
      );
    }
  }

  bool _detectMouthOpen(Map<FaceLandmarkType, FaceLandmark?> landmarks) {
    // Get available mouth landmarks
    final leftMouth = landmarks[FaceLandmarkType.leftMouth];
    final rightMouth = landmarks[FaceLandmarkType.rightMouth];
    final noseBase = landmarks[FaceLandmarkType.noseBase];
    final bottomMouth = landmarks[FaceLandmarkType.bottomMouth];

    if (leftMouth == null || rightMouth == null || noseBase == null) {
      return false;
    }

    // Calculate mouth width (horizontal distance between corners)
    final mouthWidth =
        (rightMouth.position.x - leftMouth.position.x).abs().toDouble();

    // If bottomMouth landmark exists, use it for height calculation
    if (bottomMouth != null) {
      // Use average Y position of mouth corners for top
      final mouthTopY =
          ((leftMouth.position.y + rightMouth.position.y) / 2).toDouble();
      final mouthHeight = (bottomMouth.position.y - mouthTopY).abs().toDouble();

      // Mouth is open if height is significant relative to width
      return mouthHeight > (mouthWidth * 0.3);
    } else {
      // Fallback: use distance from nose to mouth as indicator
      final mouthCenterY =
          ((leftMouth.position.y + rightMouth.position.y) / 2).toDouble();
      final verticalDistance =
          (mouthCenterY - noseBase.position.y).abs().toDouble();

      // Mouth is open if it's far enough from nose
      return verticalDistance > (mouthWidth * 0.4);
    }
  }

  bool shouldPlayAudio() {
    return state.isMouthOpen && state.wasMouthClosedBefore;
  }

  @override
  Future<void> dispose() async {
    await _faceDetector.close();
  }
}
