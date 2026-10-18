import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:userapp/core/network/api_client.dart';
import 'package:userapp/core/state/app_state.dart';
import 'package:userapp/core/state/session_store.dart';

String token(String id) =>
    'header.${base64Url.encode(utf8.encode(jsonEncode({'sub': id, 'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000})))}.signature';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() async {
    await sessionStore.clear();
  });
  test('logout wins over an earlier queued profile save', () async {
    apiClient.setAccessToken(token('old'));
    final save = sessionStore.save(
      AppState(customerId: 'old', name: 'Old name'),
    );
    final clear = sessionStore.clear();
    await Future.wait([save, clear]);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('customer_access_token'), isNull);
    expect(prefs.getString('customer_id'), isNull);
    expect(appState.value.customerId, isNull);
  });
  test(
    'switching accounts cannot pair a new token with old profile data',
    () async {
      apiClient.setAccessToken(token('old'));
      final oldSave = sessionStore.save(
        AppState(customerId: 'old', name: 'Old name'),
      );
      final clear = sessionStore.clear();
      final newToken = token('new');
      apiClient.setAccessToken(newToken);
      final newSave = sessionStore.save(
        AppState(customerId: 'new', name: 'New name'),
      );
      await Future.wait([oldSave, clear, newSave]);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('customer_access_token'), newToken);
      expect(prefs.getString('customer_id'), 'new');
      expect(prefs.getString('customer_name'), 'New name');
    },
  );
  test('a late restore cannot replace a newer in-memory session', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('customer_access_token', token('old'));
    await prefs.setString('customer_id', 'old');
    final restore = sessionStore.restore();
    apiClient.setAccessToken(token('new'));
    appState.value = AppState(customerId: 'new');
    expect(await restore, isFalse);
    expect(appState.value.customerId, 'new');
  });
}
