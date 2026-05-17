import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_theme.dart';
import '../data/image_compressor.dart';
import '../data/scan_repository.dart';
import '../domain/scan_models.dart';
import '../providers/scan_provider.dart';
import 'widgets/scan_analyzing_overlay.dart';

enum _CameraPermissionState {
  checking,
  granted,
  denied,
  permanentlyDenied,
}

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  _CameraPermissionState _permissionState = _CameraPermissionState.checking;
  bool _isCapturing = false;
  bool _isAnalyzing = false;
  Uint8List? _analyzingPreview;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    setState(() => _permissionState = _CameraPermissionState.checking);

    final status = await Permission.camera.request();
    if (!mounted) {
      return;
    }

    if (status.isGranted) {
      await _setupCamera();
      return;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      setState(
        () => _permissionState = _CameraPermissionState.permanentlyDenied,
      );
    } else {
      setState(() => _permissionState = _CameraPermissionState.denied);
    }
  }

  Future<void> _setupCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _permissionState = _CameraPermissionState.denied);
        return;
      }

      final camera = _cameras.firstWhere(
        (description) => description.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _permissionState = _CameraPermissionState.granted;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _permissionState = _CameraPermissionState.denied);
      }
    }
  }

  Future<void> _captureAndScan() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final photo = await controller.takePicture();
      final rawBytes = await photo.readAsBytes();
      final compressed = await ImageCompressor.compressForUpload(
        Uint8List.fromList(rawBytes),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isCapturing = false;
        _isAnalyzing = true;
        _analyzingPreview = compressed;
      });

      final base64Image = ScanRepository.toBase64(compressed);
      final result = await ref.read(scanRepositoryProvider).identifyPokemon(
            base64Image,
          );

      if (!mounted) {
        return;
      }

      setScanSession(
        ref,
        ScanSession(
          result: result,
          previewImageBytes: compressed,
        ),
      );

      setState(() {
        _isAnalyzing = false;
        _analyzingPreview = null;
      });

      context.push('/scan-result');
    } catch (_) {
      if (!mounted) {
        return;
      }

      setScanSession(
        ref,
        ScanSession(
          result: ScanResult.error(),
          previewImageBytes: _analyzingPreview,
        ),
      );

      setState(() {
        _isCapturing = false;
        _isAnalyzing = false;
        _analyzingPreview = null;
      });

      context.push('/scan-result');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAnalyzing && _analyzingPreview != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: ScanAnalyzingOverlay(imageBytes: _analyzingPreview!),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBody(),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
          if (_permissionState == _CameraPermissionState.granted &&
              _controller != null)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: _CaptureButton(
                    onPressed: _isCapturing ? null : _captureAndScan,
                    isLoading: _isCapturing,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_permissionState) {
      case _CameraPermissionState.checking:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        );
      case _CameraPermissionState.granted:
        final controller = _controller;
        if (controller == null || !controller.value.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }
        return CameraPreview(controller);
      case _CameraPermissionState.denied:
        return _PermissionMessage(
          message: 'Camera access is required to scan Pokémon.',
          primaryLabel: 'Try Again',
          onPrimary: _initCamera,
        );
      case _CameraPermissionState.permanentlyDenied:
        return _PermissionMessage(
          message: 'Camera access is required to scan Pokémon.',
          primaryLabel: 'Open Settings',
          onPrimary: openAppSettings,
          secondaryLabel: 'Try Again',
          onSecondary: _initCamera,
        );
    }
  }
}

class _PermissionMessage extends StatelessWidget {
  const _PermissionMessage({
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.onPrimary,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onPrimary,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: Text(primaryLabel),
            ),
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onSecondary,
                child: Text(
                  secondaryLabel!,
                  style: const TextStyle(color: AppColors.accent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.onPressed,
    required this.isLoading,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      color: AppColors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 88,
          height: 88,
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                )
              : const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 42,
                ),
        ),
      ),
    );
  }
}
