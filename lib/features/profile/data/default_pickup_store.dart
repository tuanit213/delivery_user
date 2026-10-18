import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DefaultPickupLocation {
  const DefaultPickupLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String address;
  final double latitude;
  final double longitude;

  bool get isValid =>
      address.trim().isNotEmpty &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

class DefaultPickupStore {
  const DefaultPickupStore();

  String _prefix(String customerId) =>
      'customer_default_pickup_${customerId.trim()}';

  Future<DefaultPickupLocation?> load(String customerId) async {
    if (customerId.trim().isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final prefix = _prefix(customerId);

    final stored = prefs.getString('${prefix}_location');
    if (stored != null) {
      final data = jsonDecode(stored) as Map<String, dynamic>;
      final result = DefaultPickupLocation(
        address: data['address'] as String,
        latitude: (data['latitude'] as num).toDouble(),
        longitude: (data['longitude'] as num).toDouble(),
      );
      if (!result.isValid) {
        throw const FormatException('Điểm lấy không hợp lệ.');
      }
      return result;
    }

    final address = prefs.getString('${prefix}_address');
    final latitude = prefs.getDouble('${prefix}_latitude');
    final longitude = prefs.getDouble('${prefix}_longitude');

    if (address == null ||
        address.trim().isEmpty ||
        latitude == null ||
        longitude == null) {
      return null;
    }

    final result = DefaultPickupLocation(
      address: address.trim(),
      latitude: latitude,
      longitude: longitude,
    );

    return result.isValid ? result : null;
  }

  Future<void> save(String customerId, DefaultPickupLocation location) async {
    if (customerId.trim().isEmpty) {
      throw ArgumentError('customerId không được để trống.');
    }

    if (!location.isValid) {
      throw ArgumentError('Điểm lấy mặc định không hợp lệ.');
    }

    final prefs = await SharedPreferences.getInstance();
    final prefix = _prefix(customerId);

    final saved = await prefs.setString(
      '${prefix}_location',
      jsonEncode({
        'address': location.address.trim(),
        'latitude': location.latitude,
        'longitude': location.longitude,
      }),
    );
    if (!saved) throw StateError('Không thể lưu điểm lấy trên thiết bị.');
  }

  Future<void> clear(String customerId) async {
    if (customerId.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final prefix = _prefix(customerId);

    final results = await Future.wait([
      prefs.remove('${prefix}_location'),
      prefs.remove('${prefix}_address'),
      prefs.remove('${prefix}_latitude'),
      prefs.remove('${prefix}_longitude'),
    ]);
    if (results.any((success) => !success)) {
      throw StateError('Không thể xóa điểm lấy trên thiết bị.');
    }
  }
}

const defaultPickupStore = DefaultPickupStore();
