import 'package:latlong2/latlong.dart';

import '../../../core/network/api_client.dart';
import 'orders_api.dart';

LatLng? trackingPosition(Object? latitude, Object? longitude) {
  if (latitude is! num || longitude is! num) return null;
  final lat = latitude.toDouble(), lng = longitude.toDouble();
  if (!lat.isFinite || !lng.isFinite || lat.abs() > 90 || lng.abs() > 180) {
    return null;
  }
  return LatLng(lat, lng);
}

class DriverTrackingSnapshot {
  DriverTrackingSnapshot(this.order, this.driver);
  final Map<String, dynamic> order;
  final Map<String, dynamic>? driver;
  LatLng? get position =>
      trackingPosition(driver?['latitude'], driver?['longitude']);
  LatLng? get pickup => trackingPosition(order['viDoLay'], order['kinhDoLay']);
}

class DriverTrackingApi {
  DriverTrackingApi(this.client);
  final ApiClient client;

  bool _canTrack(Map<String, dynamic> order) =>
      order['maSp'] != null &&
      !isCustomerOrderClosed(order['trangThai']?.toString() ?? '');

  Future<Map<String, dynamic>> _order(String id) async =>
      Map<String, dynamic>.from(await client.get('/api/order/$id') as Map);

  Future<Map<String, dynamic>> _location(
    String orderId,
    Object driverId,
  ) async => Map<String, dynamic>.from(
    await client.get(
          '/api/identity/shippers/$driverId/location',
          query: {'orderId': orderId},
        )
        as Map,
  );

  Future<DriverTrackingSnapshot> load(String orderId) async {
    final order = await _order(orderId);
    if (!_canTrack(order)) return DriverTrackingSnapshot(order, null);
    try {
      return DriverTrackingSnapshot(
        order,
        await _location(orderId, order['maSp']),
      );
    } on ApiException catch (error) {
      if (![403, 404, 409].contains(error.statusCode)) rethrow;

      final latest = await _order(orderId);
      if (!_canTrack(latest)) return DriverTrackingSnapshot(latest, null);
      if (latest['maSp'] == order['maSp']) rethrow;
      return DriverTrackingSnapshot(
        latest,
        await _location(orderId, latest['maSp']),
      );
    }
  }
}
