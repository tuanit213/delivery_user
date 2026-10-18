import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart' hide Badge;
import 'package:userapp/theme/app_fonts.dart';

import '../../../core/network/api_client.dart';
import '../../../core/state/app_state.dart';
import '../../../core/state/polling_controller.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/refresh_notice.dart';
import '../../../theme/app_colors.dart';
import '../data/orders_api.dart';
import 'live_order_map.dart';
import 'order_actions.dart';
import 'widgets/customer_order_tile.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, this.api});
  final OrdersApi? api;
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
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
    appBar: const PageHeader('Danh sách đơn hàng'),
    bottomNavigationBar: const AppNav(1),
    body: ContentFrame(child: _buildBody()),
  );

  Widget _buildBody() {
    if (_orders.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_orders.error != null && _orders.data == null) {
      return Center(
        child: PrimaryButton(
          'Tải lại',
          icon: Icons.refresh,
          onTap: _orders.refresh,
        ),
      );
    }

    final orders = _orders.data ?? [];

    return RefreshIndicator(
      onRefresh: _orders.refresh,
      child: ListView(
        key: const PageStorageKey<String>('customer-orders-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_orders.error != null)
            RefreshNotice(
              updatedAt: _orders.updatedAt,
              isRefreshing: _orders.isRefreshing,
              onRetry: _orders.refresh,
            ),
          if (orders.isEmpty)
            const CardBox(child: Text('Bạn chưa có đơn hàng nào.'))
          else
            ...orders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CustomerOrderTile(order),
              ),
            ),
        ],
      ),
    );
  }
}

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key, required this.orderId, this.api});

  final OrdersApi? api;

  final String orderId;

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  late PollingController<OrderDetailData> _detail;

  @override
  void initState() {
    super.initState();
    _startDetail();
  }

  void _startDetail() {
    final orderId = widget.orderId;
    final api = widget.api ?? ordersApi;
    _detail = PollingController(() async {
      final value = await api.detailById(orderId);
      if (value == null) {
        throw const ApiException(404, '{"message":"Không tìm thấy đơn hàng."}');
      }
      return value;
    })..addListener(_redraw);
    _detail.start();
  }

  @override
  void didUpdateWidget(covariant StatusScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId || oldWidget.api != widget.api) {
      _detail.dispose();
      _startDetail();
    }
  }

  void _redraw() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  String _display(String? value, {String fallback = '---'}) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _money(num value) {
    final raw = value.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < raw.length; i++) {
      final remaining = raw.length - i;
      buffer.write(raw[i]);

      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${buffer.toString()} đ';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('Chi tiết đơn hàng', fallbackRoute: '/orders'),
    body: ContentFrame(child: _buildBody()),
  );

  Widget _buildBody() {
    if (_detail.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_detail.data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _detail.error is ApiException
                  ? _detail.error.toString()
                  : 'Không thể tải thông tin đơn hàng. Vui lòng thử lại.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _detail.refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lại'),
            ),
          ],
        ),
      );
    }

    final detail = _detail.data!;
    final order = detail.order;

    return ListView(
      key: PageStorageKey<String>('customer-order-detail-${widget.orderId}'),
      padding: const EdgeInsets.all(16),
      children: [
        if (_detail.error != null)
          RefreshNotice(
            updatedAt: _detail.updatedAt,
            isRefreshing: _detail.isRefreshing,
            onRetry: _detail.refresh,
          ),
        OrderActions(
          orderId: order.id,
          status: order.status,
          enabled: _detail.error == null,
          onChanged: _detail.refresh,
        ),
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mã đơn: ${order.id}',
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Badge(customerOrderStatusLabel(order.status), color: appRed),
            ],
          ),
        ),

        const SizedBox(height: 14),

        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin người gửi',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 22),
              _InfoLine(
                icon: Icons.person_outline,
                label: 'Họ tên',
                value: _display(order.senderName),
              ),
              _InfoLine(
                icon: Icons.phone_outlined,
                label: 'Số điện thoại',
                value: _display(order.senderPhone),
              ),
              _InfoLine(
                icon: Icons.location_on_outlined,
                label: 'Địa chỉ lấy',
                value: _display(order.pickupAddress),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin người nhận',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 22),
              _InfoLine(
                icon: Icons.person_outline,
                label: 'Họ tên',
                value: _display(order.receiverName),
              ),
              _InfoLine(
                icon: Icons.phone_outlined,
                label: 'Số điện thoại',
                value: _display(order.receiverPhone),
              ),
              _InfoLine(
                icon: Icons.location_on_outlined,
                label: 'Địa chỉ giao',
                value: _display(order.deliveryAddress),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin đơn hàng',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 22),
              _InfoLine(
                icon: Icons.scale_outlined,
                label: 'Khối lượng',
                value: order.weightKg == null ? '---' : '${order.weightKg} kg',
              ),
              _InfoLine(
                icon: Icons.straighten_outlined,
                label: 'Kích thước',
                value: _display(order.sizeText),
              ),
              _InfoLine(
                icon: Icons.route_outlined,
                label: 'Quãng đường',
                value: order.distanceKm == null
                    ? '---'
                    : '${order.distanceKm} km',
              ),
              _InfoLine(
                icon: Icons.payments_outlined,
                label: 'COD',
                value: _money(order.codAmount),
              ),
              _InfoLine(
                icon: Icons.local_shipping_outlined,
                label: 'Phí vận chuyển',
                value: _money(order.shippingFee),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lịch sử trạng thái',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              if (detail.history.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Chưa có lịch sử trạng thái.'),
                )
              else
                ...detail.history.asMap().entries.map(
                  (entry) => _HistoryItem(
                    item: entry.value,
                    isLast: entry.key == detail.history.length - 1,
                  ),
                ),
            ],
          ),
        ),

        if (detail.proof != null) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProofScreen(orderId: order.id),
                  ),
                );
              },
              icon: const Icon(Icons.verified_outlined),
              label: const Text('XEM MINH CHỨNG GIAO HÀNG'),
              style: ElevatedButton.styleFrom(
                backgroundColor: appRed,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 2),
              Text(value),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.item, required this.isLast});

  final OrderStatusHistory item;
  final bool isLast;

  String _formatTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';

    final date = vietnamTime(raw);

    if (date == null) return raw;

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(date.hour)}:${two(date.minute)} '
        '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final timeText = _formatTime(item.time);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Icon(
                isLast
                    ? Icons.radio_button_checked
                    : Icons.check_circle_outline,
                color: appRed,
                size: 20,
              ),
              if (!isLast)
                Container(width: 2, height: 54, color: Colors.red.shade100),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerOrderStatusLabel(item.status),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (timeText.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    timeText,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  customerHistoryDescription(
                    item.status,
                    backendNote: item.note,
                  ),
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key, required this.orderId});
  final String orderId;
  @override
  Widget build(BuildContext context) => LiveOrderMap(orderId: orderId);
}

class ProofScreen extends StatefulWidget {
  const ProofScreen({super.key, required this.orderId, this.api});
  final String orderId;
  final OrdersApi? api;

  @override
  State<ProofScreen> createState() => _ProofScreenState();
}

class _ProofScreenState extends State<ProofScreen> {
  late Future<OrderDetailData?> _proof;

  @override
  void initState() {
    super.initState();
    _proof = _load();
  }

  Future<OrderDetailData?> _load() =>
      (widget.api ?? ordersApi).detailById(widget.orderId);

  @override
  void didUpdateWidget(covariant ProofScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId || oldWidget.api != widget.api) {
      _proof = _load();
    }
  }

  String _formatProofTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return '';
    }

    final date = vietnamTime(raw);

    if (date == null) {
      return raw;
    }

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(date.hour)}:${two(date.minute)}'
        ' • ${two(date.day)}/${two(date.month)}/${date.year}';
  }

  Uint8List? _decodeDataUri(String? value) {
    if (value == null || value.isEmpty) return null;

    final index = value.indexOf(',');
    if (!value.startsWith('data:image/') || index < 0) {
      return null;
    }

    try {
      return base64Decode(value.substring(index + 1));
    } catch (_) {
      return null;
    }
  }

  Widget _imageFromProof(String? value, {required String emptyText}) {
    if (value == null || value.trim().isEmpty) {
      return Text(emptyText);
    }

    final bytes = _decodeDataUri(value);

    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Text('Không hiển thị được ảnh.'),
        ),
      );
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return Text(value);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        value,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Text('Không tải được ảnh.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('Minh chứng giao hàng', fallbackRoute: '/orders'),
    body: FutureBuilder<OrderDetailData?>(
      future: _proof,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Không thể tải minh chứng. Vui lòng thử lại.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _proof = _load();
                    }),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }
        if (snapshot.data == null) {
          return const Center(child: Text('Không tìm thấy đơn hàng.'));
        }
        final proof = snapshot.data!.proof;

        if (proof == null) {
          return const Center(
            child: Text('Đơn hàng chưa có minh chứng giao hàng.'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ảnh giao hàng',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _imageFromProof(
                    proof.imageUrl,
                    emptyText: 'Chưa có ảnh giao hàng.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            CardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Xác nhận người nhận',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _imageFromProof(
                    proof.otpSignature,
                    emptyText: 'Chưa có chữ ký.',
                  ),
                ],
              ),
            ),
            if (proof.time != null && proof.time!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              CardBox(
                child: Row(
                  children: [
                    const Icon(Icons.schedule_outlined, color: appRed),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Thời gian xác nhận: ${_formatProofTime(proof.time)}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    ),
  );
}
