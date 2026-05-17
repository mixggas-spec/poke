import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ScanAnalyzingOverlay extends StatefulWidget {
  const ScanAnalyzingOverlay({
    super.key,
    required this.imageBytes,
  });

  final Uint8List imageBytes;

  @override
  State<ScanAnalyzingOverlay> createState() => _ScanAnalyzingOverlayState();
}

class _ScanAnalyzingOverlayState extends State<ScanAnalyzingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background.withValues(alpha: 0.92),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            const Text(
              'Analyzing image...',
              style: TextStyle(
                color: AppColors.onPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: child,
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _ScanLinePainter(
                              progress: _controller.value,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.35 + (_controller.value * 0.45),
                                  ),
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  child: Image.memory(
                    widget.imageBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  _ScanLinePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.accent.withValues(alpha: 0),
          AppColors.accent,
          AppColors.accent.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, y - 24, size.width, 48));

    canvas.drawRect(
      Rect.fromLTWH(0, y - 2, size.width, 4),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
