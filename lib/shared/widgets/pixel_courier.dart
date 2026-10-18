import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'pixel_order_scene.dart';

class PixelCourier extends StatelessWidget {
  const PixelCourier({super.key});

  @override
  Widget build(BuildContext context) => const PixelOrderScene();
}

class PixelGrid extends CustomPainter {
  const PixelGrid();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.line.withValues(alpha: .13)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant PixelGrid oldDelegate) => false;
}
