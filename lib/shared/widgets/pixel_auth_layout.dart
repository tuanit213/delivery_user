import 'package:flutter/material.dart';
import 'package:userapp/theme/app_fonts.dart';

import '../../theme/app_colors.dart';
import 'app_widgets.dart';
import 'pixel_courier.dart';

class PixelAuthLayout extends StatelessWidget {
  const PixelAuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
    this.registration = false,
  });
  final String title, subtitle;
  final Widget child, footer;
  final bool registration;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: CustomPaint(
      painter: const PixelGrid(),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, bounds) {
            final wide = bounds.maxWidth >= 900;
            final form = CardBox(
              padding: EdgeInsets.all(wide ? 32 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(width: 8, height: 8, color: AppColors.amber),
                      const SizedBox(width: 8),
                      Text(
                        registration
                            ? 'THÀNH VIÊN MỚI'
                            : 'TRẠM GIAO HÀNG CỦA BẠN',
                        style: TextStyle(
                          fontFamily: AppFonts.mono,
                          fontSize: 10,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 27,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 28),
                  child,
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.line),
                  const SizedBox(height: 10),
                  footer,
                ],
              ),
            );
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 40 : 20,
                vertical: wide ? 36 : 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (bounds.maxHeight - (wide ? 72 : 48)).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(flex: 6, child: _hero(true)),
                              const SizedBox(width: 64),
                              Expanded(flex: 5, child: form),
                            ],
                          )
                        : ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _hero(false),
                                const SizedBox(height: 24),
                                form,
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget _hero(bool wide) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Brand(large: wide),
      SizedBox(height: wide ? 48 : 22),
      if (wide) ...[
        const Text(
          'Gửi một món hàng.\nKết nối một hành trình.',
          style: TextStyle(
            fontSize: 38,
            height: 1.35,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.4,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Từ lúc tạo đơn đến khi trao tay,\nLogiRoute luôn đồng hành cùng bạn.',
          style: TextStyle(fontSize: 14, height: 1.9, color: AppColors.muted),
        ),
        const SizedBox(height: 30),
      ],
      Container(
        decoration: const BoxDecoration(
          border: Border.fromBorderSide(
            BorderSide(color: AppColors.text, width: 2),
          ),
          boxShadow: [
            BoxShadow(color: Color(0xFFD4DBCF), offset: Offset(5, 5)),
          ],
        ),
        child: Column(
          children: [
            Container(
              color: AppColors.panel,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  for (final color in [
                    AppColors.amber,
                    const Color(0xFFF1C766),
                    AppColors.green,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: Container(width: 6, height: 6, color: color),
                    ),
                  const Spacer(),
                  Text(
                    'LOGIROUTE / PIXEL DELIVERY',
                    style: TextStyle(
                      fontFamily: AppFonts.mono,
                      fontSize: 9,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const PixelCourier(),
          ],
        ),
      ),
      if (wide) ...[
        const SizedBox(height: 26),
        Row(
          children: [
            _step('01', 'Tạo đơn'),
            const Expanded(child: Divider(indent: 12, endIndent: 12)),
            _step('02', 'Theo dõi'),
            const Expanded(child: Divider(indent: 12, endIndent: 12)),
            _step('03', 'Trao tay'),
          ],
        ),
      ],
    ],
  );

  Widget _step(String number, String label) => Row(
    children: [
      Text(
        number,
        style: TextStyle(
          fontFamily: AppFonts.mono,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.red,
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
    ],
  );
}
