import 'package:camera/camera.dart' as cam;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraControllerWrapper {
  late cam.CameraController _controller;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  cam.CameraController get controller => _controller;

  Future<void> initialize() async {
    try {
      final cameraStatus = await Permission.camera.request();

      if (cameraStatus.isDenied) {
        throw Exception('Camera permission denied');
      }

      final cameras = await cam.availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == cam.CameraLensDirection.front,
        orElse: () => cameras[0],
      );

      _controller = cam.CameraController(
        frontCamera,
        cam.ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller.initialize();
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize camera: $e');
    }
  }

  Future<void> dispose() async {
    if (_isInitialized) {
      await _controller.dispose();
      _isInitialized = false;
    }
  }

  Future<cam.XFile> takePicture() async {
    if (!_isInitialized) {
      throw Exception('Camera not initialized');
    }
    return await _controller.takePicture();
  }
}

final cameraControllerProvider =
    StateNotifierProvider<CameraControllerNotifier, CameraControllerState>(
  (ref) => CameraControllerNotifier(),
);

class CameraControllerState {
  final bool isInitialized;
  final String? error;
  final CameraControllerWrapper? camera;

  CameraControllerState({
    this.isInitialized = false,
    this.error,
    this.camera,
  });

  CameraControllerState copyWith({
    bool? isInitialized,
    String? error,
    CameraControllerWrapper? camera,
  }) {
    return CameraControllerState(
      isInitialized: isInitialized ?? this.isInitialized,
      error: error ?? this.error,
      camera: camera ?? this.camera,
    );
  }
}

class CameraControllerNotifier extends StateNotifier<CameraControllerState> {
  CameraControllerNotifier() : super(CameraControllerState());

  Future<void> initialize() async {
    try {
      final cameraCtrl = CameraControllerWrapper();
      await cameraCtrl.initialize();
      state = state.copyWith(
        isInitialized: true,
        camera: cameraCtrl,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isInitialized: false,
      );
    }
  }

  @override
  Future<void> dispose() async {
    if (state.camera != null) {
      await state.camera!.dispose();
      state = CameraControllerState();
    }
  }
}
