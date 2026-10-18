import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';
import '../network/api_client.dart';
import '../../features/orders/data/orders_api.dart';

class SessionStore {
  Timer? _expiry;
  Future<void> _storageQueue = Future.value();

  Future<void> _persist(
    int revision,
    Future<void> Function(SharedPreferences) write,
  ) {
    final operation = _storageQueue.then((_) async {
      if (revision != apiClient.sessionRevision) return;
      final prefs = await SharedPreferences.getInstance();
      if (revision == apiClient.sessionRevision) await write(prefs);
    });
    _storageQueue = operation.catchError((Object _) {});
    return operation;
  }

  SessionStore() {
    apiClient.onUnauthorized = clear;
  }
  DateTime? _expires(String token) {
    try {
      final payload =
          jsonDecode(
                utf8.decode(
                  base64Url.decode(base64Url.normalize(token.split('.')[1])),
                ),
              )
              as Map;
      return DateTime.fromMillisecondsSinceEpoch(
        (payload['exp'] as num).toInt() * 1000,
        isUtc: true,
      );
    } catch (_) {
      return null;
    }
  }

  bool _watch(String token) {
    _expiry?.cancel();
    final end = _expires(token);
    if (end == null || !end.isAfter(DateTime.now().toUtc())) return false;
    _expiry = Timer(end.difference(DateTime.now().toUtc()), () {
      unawaited(clear());
    });
    return true;
  }

  static const _token = 'customer_access_token';
  static const _customerId = 'customer_id';
  static const _name = 'customer_name';
  static const _phone = 'customer_phone';
  static const _email = 'customer_email';
  static const _address = 'customer_address';

  Future<bool> restore() async {
    final revision = apiClient.sessionRevision;
    final prefs = await SharedPreferences.getInstance();
    if (revision != apiClient.sessionRevision) return false;
    final customerId = prefs.getString(_customerId);
    final token = prefs.getString(_token);
    if (customerId == null ||
        customerId.isEmpty ||
        token == null ||
        token.isEmpty) {
      return false;
    }
    if (!_watch(token)) {
      await clear();
      return false;
    }
    apiClient.setAccessToken(token);
    appState.value = AppState(
      customerId: customerId,
      name: prefs.getString(_name) ?? '',
      phone: prefs.getString(_phone) ?? '',
      email: prefs.getString(_email) ?? '',
      defaultAddress: prefs.getString(_address) ?? '',
    );
    return true;
  }

  Future<void> save(AppState state) async {
    final revision = apiClient.sessionRevision;
    final token = apiClient.accessToken ?? '';
    if (!_watch(token)) {
      await clear();
      return;
    }
    await _persist(revision, (prefs) async {
      await prefs.setString(_token, token);
      await prefs.setString(_customerId, state.customerId ?? '');
      await prefs.setString(_name, state.name);
      await prefs.setString(_phone, state.phone);
      await prefs.setString(_email, state.email);
      await prefs.setString(_address, state.defaultAddress);
    });
  }

  Future<void> clear() async {
    _expiry?.cancel();
    appState.value = AppState();
    apiClient.setAccessToken(null);
    ordersApi.clearCache();
    await _persist(apiClient.sessionRevision, (prefs) async {
      await Future.wait([
        prefs.remove(_token),
        prefs.remove(_customerId),
        prefs.remove(_name),
        prefs.remove(_phone),
        prefs.remove(_email),
        prefs.remove(_address),
      ]);
    });
  }
}

final sessionStore = SessionStore();
