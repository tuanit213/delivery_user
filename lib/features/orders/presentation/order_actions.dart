import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/date_time_utils.dart';
import 'live_order_map.dart';

class OrderActions extends StatefulWidget {
  const OrderActions({
    super.key,
    required this.orderId,
    required this.status,
    required this.onChanged,
    this.client,
    this.enabled = true,
  });
  final String orderId, status;
  final ApiClient? client;
  final bool enabled;
  final VoidCallback onChanged;
  @override
  State<OrderActions> createState() => _OrderActionsState();
}

typedef _ActionScope = ({
  int operation,
  int session,
  String orderId,
  ApiClient client,
  VoidCallback changed,
});

class _OrderActionsState extends State<OrderActions> {
  bool busy = false;
  int _operation = 0;
  DialogRoute<Object>? _dialog;
  Timer? _dialogTimer;

  bool _current(_ActionScope scope) =>
      mounted &&
      scope.operation == _operation &&
      scope.session == scope.client.sessionRevision;

  void _dismissDialog() {
    _dialogTimer?.cancel();
    _dialogTimer = null;
    final route = _dialog;
    _dialog = null;
    if (route == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = route.navigator;
      if (navigator != null && navigator.mounted && route.isActive) {
        navigator.removeRoute(route);
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void didUpdateWidget(covariant OrderActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId ||
        oldWidget.status != widget.status ||
        oldWidget.client != widget.client ||
        oldWidget.enabled != widget.enabled) {
      _operation++;
      busy = false;
      _dismissDialog();
    }
  }

  @override
  void dispose() {
    _operation++;
    _dismissDialog();
    super.dispose();
  }

  Future<Object?> _showDialog(
    _ActionScope scope,
    WidgetBuilder builder, {
    DateTime? expiresAt,
  }) async {
    if (!_current(scope)) return null;
    final route = DialogRoute<Object>(context: context, builder: builder);
    _dialog = route;
    final timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!_current(scope) ||
          (expiresAt != null && !DateTime.now().isBefore(expiresAt))) {
        _dismissDialog();
      }
    });
    _dialogTimer = timer;
    try {
      return await Navigator.of(context, rootNavigator: true).push(route);
    } finally {
      timer.cancel();
      if (identical(_dialogTimer, timer)) _dialogTimer = null;
      if (identical(_dialog, route)) _dialog = null;
    }
  }

  Future<void> run(Future<void> Function(_ActionScope scope) action) async {
    if (busy || !widget.enabled) return;
    final client = widget.client ?? apiClient;
    final scope = (
      operation: ++_operation,
      session: client.sessionRevision,
      orderId: widget.orderId,
      client: client,
      changed: widget.onChanged,
    );
    setState(() => busy = true);
    try {
      await action(scope);
    } catch (e) {
      if (mounted && _current(scope)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted && scope.operation == _operation) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> cancel() => run((scope) async {
    final yes = await _showDialog(
      scope,
      (ctx) => AlertDialog(
        title: const Text('Hủy đơn hàng?'),
        content: const Text('Đơn đang chờ phân công sẽ được hủy.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Giữ đơn'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );
    if (yes != true || !_current(scope)) return;
    await scope.client.patch(
      '/api/order/${scope.orderId}/status',
      data: 'CANCELLED',
    );
    if (_current(scope)) scope.changed();
  });

  Future<void> code() async {
    await run((scope) async {
      final result = Map<String, dynamic>.from(
        await scope.client.post('/api/delivery/${scope.orderId}/otp') as Map,
      );
      if (!_current(scope)) return;
      final code = result['code']?.toString() ?? '';
      final expiresAt = DateTime.tryParse(
        result['expiresAt']?.toString() ?? '',
      );
      if (!RegExp(r'^\d{6}$').hasMatch(code) ||
          expiresAt == null ||
          !DateTime.now().isBefore(expiresAt)) {
        throw const FormatException(
          'Mã nhận hàng không hợp lệ hoặc đã hết hạn. Vui lòng lấy mã mới.',
        );
      }
      await _showDialog(
        scope,
        (ctx) => AlertDialog(
          title: const Text('Mã xác nhận nhận hàng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(
                code,
                style: const TextStyle(
                  fontSize: 40,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hết hạn: ${vietnamDateTimeLabel(result['expiresAt']?.toString())}',
              ),
              const SizedBox(height: 12),
              const Text(
                'Chỉ đưa mã cho tài xế khi người nhận đã nhận hàng. Mã hiển thị trong ứng dụng, không gửi SMS.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
          ],
        ),
        expiresAt: expiresAt,
      );
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (widget.status == 'PENDING')
          OutlinedButton.icon(
            onPressed: busy || !widget.enabled ? null : cancel,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Hủy đơn'),
          ),
        if ([
          'ASSIGNED',
          'ACCEPTED',
          'DELIVERING',
          'FAILED',
        ].contains(widget.status))
          OutlinedButton.icon(
            onPressed: !widget.enabled
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => LiveOrderMap(orderId: widget.orderId),
                    ),
                  ),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Theo dõi tài xế'),
          ),
        if (widget.status == 'DELIVERING')
          FilledButton.icon(
            onPressed: busy || !widget.enabled ? null : code,
            icon: const Icon(Icons.password),
            label: Text(busy ? 'Đang xử lý...' : 'Lấy mã nhận hàng'),
          ),
      ],
    ),
  );
}
