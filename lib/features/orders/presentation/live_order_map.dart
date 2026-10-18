import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/network/api_client.dart';
import '../../../core/state/polling_controller.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/refresh_notice.dart';
import '../data/driver_tracking_api.dart';

class LiveOrderMap extends StatefulWidget {
  const LiveOrderMap({
    super.key,
    required this.orderId,
    this.client,
    this.tileProvider,
  });
  final String orderId;
  final ApiClient? client;
  final TileProvider? tileProvider;
  @override
  State<LiveOrderMap> createState() => _LiveOrderMapState();
}

class _LiveOrderMapState extends State<LiveOrderMap> {
  late PollingController<DriverTrackingSnapshot> _tracking;
  final _map = MapController();
  bool _mapReady = false, _following = true;
  DriverTrackingSnapshot? _displayed;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    final id = widget.orderId;
    final api = DriverTrackingApi(widget.client ?? apiClient);
    _tracking = PollingController(() => api.load(id))..addListener(_changed);
    _tracking.start();
  }

  @override
  void didUpdateWidget(covariant LiveOrderMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId ||
        oldWidget.client != widget.client) {
      _tracking.removeListener(_changed);
      _tracking.dispose();
      _following = true;
      _displayed = null;
      _start();
    }
  }

  void _changed() {
    if (!mounted) return;
    final next = _tracking.data;
    if (next == null) _mapReady = false;
    final changed = !identical(_displayed, next);
    _displayed = next;
    setState(() {});
    if (changed && _following) _follow();
  }

  void _follow() {
    final data = _tracking.data;
    final position = data?.position ?? data?.pickup;
    if (position == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _mapReady &&
          _following &&
          identical(data, _tracking.data)) {
        _map.move(position, _map.camera.zoom);
      }
    });
  }

  @override
  void dispose() {
    _tracking.removeListener(_changed);
    _tracking.dispose();
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _tracking.data;
    final driver = data?.driver;
    final position = data?.position;
    final center = position ?? data?.pickup ?? const LatLng(10.7769, 106.7009);
    return Scaffold(
      appBar: const PageHeader('Theo dõi tài xế', fallbackRoute: '/orders'),
      body: data == null
          ? Center(
              child: _tracking.isInitialLoading
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Không thể tải vị trí tài xế. Vui lòng kiểm tra quyền truy cập và thử lại.',
                          ),
                          TextButton(
                            onPressed: _tracking.isRefreshing
                                ? null
                                : _tracking.refresh,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_tracking.error != null)
                        RefreshNotice(
                          onRetry: _tracking.refresh,
                          isRefreshing: _tracking.isRefreshing,
                          updatedAt: _tracking.updatedAt,
                        ),
                      Text(
                        driver == null
                            ? 'Chưa có tài xế hoặc đơn đã kết thúc.'
                            : (driver['name'] ?? 'Tài xế').toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (driver != null)
                        Text((driver['phone'] ?? '').toString()),
                      if (driver != null)
                        Text(
                          position == null
                              ? 'Tài xế chưa chia sẻ vị trí hợp lệ'
                              : '${driver['isStale'] == true ? 'Vị trí cũ' : 'Cập nhật'} • ${vietnamDateTimeLabel(driver['updatedAt']?.toString())}',
                        ),
                      const Text(
                        'Tự cập nhật mỗi 5 giây. Chỉ hiển thị GPS do tài xế gửi.',
                      ),
                      if (position != null)
                        TextButton.icon(
                          onPressed: () {
                            setState(() => _following = true);
                            _follow();
                          },
                          icon: const Icon(Icons.my_location),
                          label: Text(
                            _following ? 'Đang theo tài xế' : 'Theo tài xế',
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: FlutterMap(
                    mapController: _map,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 15,
                      onMapReady: () {
                        _mapReady = true;
                        _follow();
                      },
                      onPositionChanged: (_, hasGesture) {
                        if (hasGesture && _following) {
                          setState(() => _following = false);
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        tileProvider: widget.tileProvider,
                        urlTemplate: const String.fromEnvironment(
                          'MAP_TILE_URL',
                          defaultValue:
                              'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
                        ),
                        userAgentPackageName: 'vn.logiroute.customer',
                      ),
                      SimpleAttributionWidget(
                        alignment: Alignment.topRight,
                        source: const Text('OpenStreetMap contributors'),
                        onTap: () => launchUrl(
                          Uri.parse('https://www.openstreetmap.org/copyright'),
                        ),
                      ),
                      MarkerLayer(
                        markers: [
                          if (position != null)
                            Marker(
                              point: position,
                              width: 48,
                              height: 48,
                              child: const Icon(
                                Icons.delivery_dining,
                                size: 44,
                                color: Colors.teal,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
