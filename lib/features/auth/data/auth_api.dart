import '../../../core/network/api_client.dart';

class CustomerSession {
  const CustomerSession({
    required this.customerId,
    required this.name,
    required this.phone,
    this.email,
    this.defaultAddress,
  });

  final String customerId;
  final String name;
  final String phone;
  final String? email;
  final String? defaultAddress;

  factory CustomerSession.fromResponse(
    Object? response, {
    required String fallbackName,
    required String fallbackPhone,
    String? fallbackEmail,
  }) {
    final data = _asMap(response);
    final customerId = _string(data, const [
      'maKhachHang',
      'maKH',
      'maKh',
      'customerId',
      'userId',
    ]);
    if (customerId == null || customerId.isEmpty) {
      throw const FormatException(
        'Server không trả về mã khách hàng. Hãy kiểm tra response API đăng nhập/đăng ký.',
      );
    }
    return CustomerSession(
      customerId: customerId,
      name: _string(data, const ['fullName', 'hoTen', 'name']) ?? fallbackName,
      phone: _string(data, const ['soDienThoai', 'phone']) ?? fallbackPhone,
      email: _string(data, const ['email']) ?? fallbackEmail,
      defaultAddress: _string(data, const [
        'address',
        'diaChiMacDinh',
        'diaChi',
      ]),
    );
  }
}

class AuthApi {
  AuthApi({ApiClient? client}) : _client = client ?? apiClient;
  final ApiClient _client;
  Future<CustomerSession> registerCustomer({
    required String username,
    required String password,
    required String name,
    required String phone,
    String? email,
  }) async {
    await _client.post(
      '/api/identity/register',
      data: {
        'username': username,
        'password': password,
        'fullName': name,
        'soDienThoai': phone,
        'email': email,
        'role': 'CUSTOMER',
      },
    );
    return login(username: username, password: password);
  }

  Future<CustomerSession> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = _asMap(
        await _client.post(
          '/api/identity/login',
          data: {'email': username, 'password': password},
        ),
      );
      final token = response['accessToken'];
      if (token is! String || token.trim().isEmpty) {
        throw const FormatException(
          'Máy chủ không trả phiên đăng nhập hợp lệ.',
        );
      }
      _client.setAccessToken(token);
      final profile = _asMap(await _client.get('/api/identity/me'));
      if (profile['role'] != 'CUSTOMER') {
        throw const FormatException('Vui lòng dùng tài khoản khách hàng.');
      }
      return CustomerSession.fromResponse(
        profile,
        fallbackName: username,
        fallbackPhone: username,
      );
    } on SessionChangedException {
      rethrow;
    } catch (_) {
      _client.setAccessToken(null);
      rethrow;
    }
  }

  Future<CustomerSession> updateCustomer({
    required String customerId,
    required String name,
    required String phone,
    String? email,
    String? address,
  }) async {
    final response = await _client.put(
      '/api/identity/me',
      data: {
        'hoTen': name,
        'soDienThoai': phone,
        'email': email,
        'diaChi': address,
      },
    );
    return CustomerSession.fromResponse(
      response,
      fallbackName: name,
      fallbackPhone: phone,
      fallbackEmail: email,
    );
  }
}

final authApi = AuthApi();
Map<String, dynamic> _asMap(Object? value) {
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  throw const FormatException('Phản hồi từ server không có dữ liệu tài khoản.');
}

String? _string(Map<String, dynamic> data, List<String> keys) {
  final normalizedKeys = keys.map(_normalize).toSet();
  return _findValue(data, normalizedKeys);
}

String? _findValue(Object? value, Set<String> keys) {
  if (value is Map) {
    for (final entry in value.entries) {
      if (keys.contains(_normalize(entry.key.toString())) &&
          entry.value != null &&
          entry.value is! Map &&
          entry.value is! Iterable) {
        return entry.value.toString();
      }
    }
    for (final child in value.values) {
      final found = _findValue(child, keys);
      if (found != null) return found;
    }
  } else if (value is Iterable) {
    for (final child in value) {
      final found = _findValue(child, keys);
      if (found != null) return found;
    }
  }
  return null;
}

String _normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
