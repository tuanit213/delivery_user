import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:userapp/core/network/api_client.dart';
import 'package:userapp/core/state/app_state.dart';
import 'package:userapp/core/state/session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('expired JWT clears cached profile and route state', () async {
    final token =
        'header.${base64Url.encode(utf8.encode(jsonEncode({'exp': 1})))}.signature';
    SharedPreferences.setMockInitialValues({
      'customer_access_token': token,
      'customer_id': 'c1',
    });
    appState.value = AppState(customerId: 'c1');
    expect(await sessionStore.restore(), isFalse);
    expect(appState.value.customerId, isNull);
    expect(apiClient.accessToken, isNull);
    expect(
      (await SharedPreferences.getInstance()).containsKey(
        'customer_access_token',
      ),
      isFalse,
    );
  });
  test('authenticated 401 invokes the expiration callback', () async {
    var cleared = false;
    final api = ApiClient(
      client: MockClient((_) async => http.Response('', 401)),
    );
    api.onUnauthorized = () async {
      cleared = true;
      api.setAccessToken(null);
    };
    api.setAccessToken('old');
    await expectLater(api.get('/api/order'), throwsA(isA<ApiException>()));
    expect(cleared, isTrue);
    expect(api.accessToken, isNull);
  });
  test('late 401 cannot clear a newer login', () async {
    var cleared = false;
    late ApiClient api;
    api = ApiClient(
      client: MockClient((_) async {
        api.setAccessToken('new');
        return http.Response('', 401);
      }),
    );
    api.onUnauthorized = () async {
      cleared = true;
    };
    api.setAccessToken('old');
    await expectLater(api.get('/api/order'), throwsA(isA<ApiException>()));
    expect(cleared, isFalse);
    expect(api.accessToken, 'new');
  });
}
