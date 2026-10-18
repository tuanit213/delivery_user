import 'package:flutter/material.dart' hide Badge;
import 'package:go_router/go_router.dart';
import 'package:userapp/theme/app_fonts.dart';

import '../../../../shared/widgets/app_widgets.dart';
import '../../../../theme/app_colors.dart';
import '../../data/orders_api.dart';

class CustomerOrderTile extends StatelessWidget {
  const CustomerOrderTile(this.order, {super.key, this.showMoney = true});
  final CustomerOrder order;
  final bool showMoney;

  String _money(num amount) {
    final raw = amount.round().toString();
    return '${raw.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')} đ';
  }

  @override
  Widget build(BuildContext context) {
    final complete = isCustomerOrderCompleted(order.status);
    final color = complete ? AppColors.green : AppColors.red;
    final shortId = order.id.length > 8 ? order.id.substring(0, 8) : order.id;
    return Semantics(
      button: true,
      label: 'Xem đơn hàng ${order.id}',
      child: InkWell(
        onTap: () => context.push('/orders/${order.id}/status'),
        child: CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 14,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: const Color(0xFFFBE5C9),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          size: 20,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Tooltip(
                          message: order.id,
                          child: Text(
                            '#${shortId.toUpperCase()}',
                            style: TextStyle(
                              fontFamily: AppFonts.mono,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Badge(customerOrderStatusLabel(order.status), color: color),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      order.deliveryAddress.isEmpty
                          ? 'Chưa có địa chỉ giao'
                          : order.deliveryAddress,
                      style: const TextStyle(fontSize: 13, height: 1.6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 17,
                    color: AppColors.muted,
                  ),
                ],
              ),
              if (showMoney) ...[
                const Divider(height: 30),
                Wrap(
                  spacing: 32,
                  runSpacing: 12,
                  children: [
                    _amount('THU HỘ COD', _money(order.codAmount)),
                    _amount('PHÍ GIAO HÀNG', _money(order.shippingFee)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _amount(String label, String amount) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.mono,
          fontSize: 9,
          letterSpacing: .8,
          color: AppColors.muted,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        amount,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ],
  );
}
