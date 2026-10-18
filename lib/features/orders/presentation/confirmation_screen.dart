import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/pixel_order_scene.dart';
import '../../../theme/app_colors.dart';

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key, this.orderId});
  final String? orderId;

  @override
  Widget build(BuildContext context) {
    final id = orderId?.trim();
    final confirmed = id != null && id.isNotEmpty;
    return Scaffold(
      appBar: const PageHeader('Xác nhận đơn hàng'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: CardBox(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (confirmed) ...[
                      const PixelOrderScene(confirmed: true),
                      const SizedBox(height: 24),
                      const Text(
                        'Đặt hàng thành công!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        'Mã đơn: $id',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Đơn hàng đã được lưu trên hệ thống. Bạn có thể theo dõi trạng thái trong chi tiết đơn.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, height: 1.6),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: AppColors.muted,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Chưa có thông tin đơn vừa tạo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Mở danh sách để kiểm tra các đơn hàng của bạn.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 28),
                    PrimaryButton(
                      'Xem đơn hàng',
                      icon: Icons.inventory_2_outlined,
                      onTap: () => context.go(
                        confirmed
                          ? '/orders/${Uri.encodeComponent(id)}'
                            : '/orders',
                      ),
                    ),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      'Về trang chủ',
                      outline: true,
                      onTap: () => context.go('/home'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
