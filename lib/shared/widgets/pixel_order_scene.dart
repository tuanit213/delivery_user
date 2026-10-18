import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

class PixelOrderScene extends StatefulWidget {
  const PixelOrderScene({super.key, this.confirmed = false});
  final bool confirmed;

  @override
  State<PixelOrderScene> createState() => _PixelOrderSceneState();
}

class _PixelOrderSceneState extends State<PixelOrderScene>
    with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.stop();
      _motion.value = .82;
    } else {
      _motion.repeat();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: Semantics(
      image: true,
      label: widget.confirmed
          ? 'Ảnh động pixel: kiện hàng và dấu tích xanh xác nhận đặt hàng thành công'
          : 'Minh họa pixel: bấm đặt hàng trên điện thoại, kiện hàng hiện dấu tích xanh',
      child: AspectRatio(
        aspectRatio: 1672 / 940,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/pixel-order-halloween.png',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
              excludeFromSemantics: true,
            ),
            CustomPaint(
              painter: _OrderScreenPainter(_motion, widget.confirmed),
              isComplex: true,
              willChange: !MediaQuery.disableAnimationsOf(context),
            ),
          ],
        ),
      ),
    ),
  );
}

class _OrderScreenPainter extends CustomPainter {
  _OrderScreenPainter(this.motion, this.confirmed) : super(repaint: motion);
  final Animation<double> motion;
  final bool confirmed;
  static const ink = Color(0xFF0D0919);
  static const green = Color(0xFF65F246);
  static const orange = Color(0xFFFF9D36);
  final _brush = Paint()..isAntiAlias = false;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / 1672, size.height / 940);
    final t = motion.value;
    final success = confirmed || t >= .5;
    final sending = !confirmed && t >= .38 && t < .5;

    void rect(double x, double y, double width, double height, Color color) {
      canvas.drawRect(
        Rect.fromLTWH(x, y, width, height),
        _brush..color = color,
      );
    }

    void text(String value, double y, double fontSize, Color color) {
      final painter = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: fontSize,
            height: 1.05,
            color: color,
            fontWeight: FontWeight.w700,
            shadows: const [
              Shadow(color: Color(0xFF8B42B7), offset: Offset(3, 4)),
            ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 332);
      painter.paint(canvas, Offset(845 - painter.width / 2, y));
    }

    void polygon(List<Offset> points, Color color) {
      final shape = Path()..addPolygon(points, true);
      canvas.drawPath(shape, _brush..color = color);
      canvas.drawPath(
        shape,
        Paint()
          ..color = ink
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
          ..isAntiAlias = false,
      );
    }

    rect(664, 166, 360, 644, const Color(0xFF201333));
    text('LOGIROUTE', 190, 34, orange);
    rect(700, 236, 288, 3, const Color(0xFF673C83));

    void bat(double x, double y, int index) {
      final shift = math.sin(t * math.pi * 2 + index) * 14;
      final flap = (t * 18 + index).floor().isEven ? 0.0 : 7.0;
      const color = Color(0xFF784DA1);
      rect(x + shift, y, 13, 16, color);
      rect(x + shift - 24, y - flap, 24, 7, color);
      rect(x + shift - 15, y + 7 - flap, 15, 7, color);
      rect(x + shift + 13, y - flap, 24, 7, color);
      rect(x + shift + 13, y + 7 - flap, 15, 7, color);
      rect(x + shift + 2, y + 3, 3, 3, orange);
      rect(x + shift + 9, y + 3, 3, 3, orange);
    }

    bat(957, 265, 0);
    bat(716, 751, 1);
    bat(1170, 145, 2);

    final webPaint = Paint()
      ..color = const Color(0xFF9D89B1)
      ..strokeWidth = 3
      ..isAntiAlias = false;
    for (var i = 1; i <= 3; i++) {
      canvas.drawLine(
        const Offset(669, 171),
        Offset(669 + i * 22, 237 - i * 22),
        webPaint,
      );
      canvas.drawLine(
        Offset(669, 171 + i * 18),
        Offset(669 + i * 18, 171),
        webPaint,
      );
      canvas.drawLine(
        const Offset(669, 805),
        Offset(669 + i * 20, 745 + i * 20),
        webPaint,
      );
    }

    final bounce = (math.sin(t * math.pi * 4) * 7).roundToDouble();
    canvas.save();
    canvas.translate(0, bounce);
    canvas.translate(845, 360);
    canvas.scale(1.2);
    canvas.translate(-845, -360);
    rect(762, 475, 162, 10, const Color(0xFF372044));
    polygon(const [
      Offset(750, 322),
      Offset(836, 277),
      Offset(936, 321),
      Offset(850, 369),
    ], const Color(0xFFFFD597));
    polygon(const [
      Offset(750, 322),
      Offset(850, 369),
      Offset(850, 470),
      Offset(750, 421),
    ], const Color(0xFFE9A85B));
    polygon(const [
      Offset(850, 369),
      Offset(936, 321),
      Offset(936, 422),
      Offset(850, 470),
    ], const Color(0xFFD28B44));
    polygon(const [
      Offset(791, 300),
      Offset(891, 345),
      Offset(912, 333),
      Offset(813, 288),
    ], const Color(0xFFFFE7B5));
    rect(778, 389, 8, 18, ink);
    rect(793, 397, 8, 18, ink);
    rect(775, 420, 30, 5, ink);

    if (success) {
      final reveal = confirmed ? 1.0 : ((t - .5) / .13).clamp(0.0, 1.0);
      final check = Path()
        ..moveTo(860, 401)
        ..lineTo(892, 433)
        ..lineTo(971, 345);
      final metric = check.computeMetrics().first;
      final segment = metric.extractPath(0, metric.length * reveal);
      canvas.drawPath(
        segment,
        Paint()
          ..color = ink
          ..strokeWidth = 27
          ..strokeJoin = StrokeJoin.miter
          ..style = PaintingStyle.stroke
          ..isAntiAlias = false,
      );
      canvas.drawPath(
        segment,
        Paint()
          ..color = green
          ..strokeWidth = 16
          ..strokeJoin = StrokeJoin.miter
          ..style = PaintingStyle.stroke
          ..isAntiAlias = false,
      );
      for (var i = 0; i < 7; i++) {
        final x = i.isEven ? 716.0 + (i % 3) * 18 : 960.0 + (i % 3) * 12;
        final y = 285 + i * 23.0 + math.sin(t * math.pi * 4 + i) * 10;
        final color = i.isEven ? green : AppColors.amber;
        rect(x, y, 7, 19, color);
        rect(x - 6, y + 6, 19, 7, color);
      }
    }
    canvas.restore();

    if (success) {
      text('ĐÃ ĐẶT HÀNG\nTHÀNH CÔNG', 526, 54, orange);
      rect(710, 663, 270, 66, green);
      text('ĐÃ XÁC NHẬN', 675, 38, ink);
    } else {
      text('GỬI MÓN HÀNG\nCỦA BẠN', 513, 46, orange);
      rect(710, 626, 270, 6, const Color(0xFF673C83));
      rect(706, 663, 278, 70, AppColors.amber);
      text(sending ? 'ĐANG GỬI...' : 'ĐẶT HÀNG', 676, 42, ink);
    }

    if (!confirmed && t >= .12 && t < .65) {
      final approach = ((t - .12) / .19).clamp(0.0, 1.0);
      final retreat = t > .53 ? ((t - .53) / .12).clamp(0.0, 1.0) : 0.0;
      canvas.save();
      canvas.translate(
        (1 - approach + retreat) * 220,
        (1 - approach + retreat) * 190,
      );
      if (t >= .32 && t < .4) {
        rect(859, 665, 66, 5, AppColors.amber);
        rect(850, 674, 5, 55, AppColors.amber);
        rect(930, 674, 5, 55, AppColors.amber);
      }
      polygon(const [
        Offset(881, 701),
        Offset(905, 701),
        Offset(905, 709),
        Offset(917, 709),
        Offset(917, 729),
        Offset(929, 729),
        Offset(929, 753),
        Offset(965, 753),
        Offset(965, 769),
        Offset(989, 769),
        Offset(989, 793),
        Offset(1013, 793),
        Offset(1013, 833),
        Offset(1117, 937),
        Offset(1117, 940),
        Offset(945, 940),
        Offset(905, 861),
        Offset(869, 825),
        Offset(849, 789),
        Offset(849, 773),
        Offset(865, 773),
        Offset(889, 797),
        Offset(889, 773),
        Offset(873, 733),
        Offset(873, 709),
        Offset(881, 709),
      ], const Color(0xFFF0AF84));
      rect(884, 713, 17, 17, const Color(0xFFFFD2A8));
      rect(917, 785, 10, 22, const Color(0xFFD8916C));
      rect(949, 801, 10, 22, const Color(0xFFD8916C));
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OrderScreenPainter oldDelegate) =>
      oldDelegate.motion != motion || oldDelegate.confirmed != confirmed;
}
