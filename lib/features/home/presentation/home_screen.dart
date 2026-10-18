import '../../../core/state/polling_controller.dart';
import '../../../shared/widgets/refresh_notice.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/app_state.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/pixel_courier.dart';
import '../../orders/presentation/widgets/customer_order_tile.dart';
import '../../../theme/app_colors.dart';
import '../../orders/data/orders_api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.api});
  final OrdersApi? api;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PollingController<List<CustomerOrder>> _orders;

  @override
  void initState() {
    super.initState();
    _orders = PollingController(_loadOrders)..addListener(_redraw);
    _orders.start();
  }

  Future<List<CustomerOrder>> _loadOrders() {
    final customerId = appState.value.customerId;
    return customerId == null
        ? Future.value([])
        : (widget.api ?? ordersApi).forCustomer(customerId, forceRefresh: true);
  }

  void _redraw() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _orders.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 76,
      title: const Brand(),
      centerTitle: false,
      titleSpacing: 24,
      actions: [
        IconButton(
          tooltip: 'Thông báo',
          onPressed: () => context.go('/notifications'),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        const SizedBox(width: 16),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(2),
        child: Divider(height: 2, thickness: 2, color: AppColors.text),
      ),
    ),
    bottomNavigationBar: const AppNav(0),
    body: ContentFrame(child: _buildBody()),
  );

  Widget _buildBody() {
    if (_orders.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_orders.error != null && _orders.data == null) {
      return _ErrorView(onRetry: _orders.refresh);
    }
    final orders = _orders.data ?? [];
    final active = orders
        .where((o) => isCustomerOrderActive(o.status))
        .toList();
    final completed = orders
        .where((o) => isCustomerOrderCompleted(o.status))
        .length;
    return RefreshIndicator(
      onRefresh: _orders.refresh,
      child: ListView(
        key: const PageStorageKey<String>('customer-home-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(22, 28, 26, 32),
        children: [
          if (_orders.error != null)
            RefreshNotice(
              updatedAt: _orders.updatedAt,
              isRefreshing: _orders.isRefreshing,
              onRetry: _orders.refresh,
            ),
          const Text(
            'TRẠM GIAO HÀNG CỦA BẠN',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Chào ${appState.value.name.isEmpty ? 'bạn' : appState.value.name}!',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 26,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          const _DeliveryBanner(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  active.length.toString(),
                  'Đang xử lý',
                  AppColors.red,
                  Icons.route_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _Stat(
                  completed.toString(),
                  'Đã giao thành công',
                  AppColors.green,
                  Icons.task_alt_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Đơn đang trên hành trình',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/orders'),
                child: const Text('Xem tất cả', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (active.isEmpty)
            const CardBox(
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 30,
                    color: AppColors.muted,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Mọi hành trình đều bắt đầu từ một món hàng.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600, height: 1.7),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Tạo đơn mới khi bạn sẵn sàng gửi nhé.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            )
          else
            ...active
                .take(3)
                .map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: CustomerOrderTile(order, showMoney: false),
                  ),
                ),
        ],
      ),
    );
  }
}

class _DeliveryBanner extends StatelessWidget {
  const _DeliveryBanner();

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: AppColors.panel2,
      border: Border.fromBorderSide(
        BorderSide(color: AppColors.text, width: 2),
      ),
      boxShadow: [BoxShadow(color: Color(0xFFD4DBCF), offset: Offset(4, 4))],
    ),
    child: LayoutBuilder(
      builder: (context, bounds) {
        final wide = bounds.maxWidth > 650;
        final copy = Padding(
          padding: EdgeInsets.all(wide ? 28 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Gói ghém xong rồi?\nĐể LogiRoute giao nhé.',
                style: TextStyle(
                  fontSize: 23,
                  height: 1.45,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tạo đơn, xem cước phí và theo dõi\nhành trình ngay tại đây.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.8,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 22),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: PrimaryButton(
                  'Tạo đơn hàng',
                  icon: Icons.add_rounded,
                  onTap: () => context.go('/create-order'),
                ),
              ),
            ],
          ),
        );
        return wide
            ? Row(
                children: [
                  Expanded(child: copy),
                  const Expanded(child: PixelCourier()),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [copy, const PixelCourier()],
              );
      },
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Không thể tải danh sách đơn hàng. Vui lòng thử lại.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            PrimaryButton('Tải lại', icon: Icons.refresh, onTap: onRetry),
          ],
        ),
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, this.color, this.icon);
  final String value, label;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => CardBox(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
            Icon(icon, size: 22, color: color),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.muted,
            height: 1.6,
          ),
        ),
      ],
    ),
  );
}
