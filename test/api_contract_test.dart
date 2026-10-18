import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:userapp/core/network/api_client.dart';
import 'package:userapp/core/state/app_state.dart';
import 'package:userapp/core/state/session_store.dart';
import 'package:userapp/features/auth/data/auth_api.dart';
import 'package:userapp/features/orders/data/orders_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'phone login uses identity credentials and bearer token for profile',
    () async {
      final mock = MockClient((request) async {
        if (request.url.path == '/api/identity/login') {
          expect(jsonDecode(request.body), {
            'email': '0900000001',
            'password': 'test-password',
          });
          return http.Response('{"accessToken":"test-token"}', 200);
        }
        expect(request.url.path, '/api/identity/me');
        expect(request.headers['Authorization'], 'Bearer test-token');
        return http.Response(
          jsonEncode({
            'role': 'CUSTOMER',
            'customerId': 'c-1',
            'fullName': 'Customer',
            'phone': '0900000001',
            'address': 'Address',
          }),
          200,
        );
      });
      final client = ApiClient(client: mock, baseUrl: 'http://localhost/');
      final result = await AuthApi(
        client: client,
      ).login(username: '0900000001', password: 'test-password');
      expect(result.customerId, 'c-1');
      expect(result.name, 'Customer');
      expect(result.defaultAddress, 'Address');
      mock.close();
    },
  );
  test('non-customer login clears the pending token', () async {
    final mock = MockClient(
      (request) async => http.Response(
        request.url.path.endsWith('/login')
            ? '{"accessToken":"test-token"}'
            : '{"role":"ADMIN"}',
        200,
      ),
    );
    final client = ApiClient(client: mock);
    await expectLater(
      AuthApi(client: client).login(username: 'admin', password: 'password'),
      throwsFormatException,
    );
    expect(client.accessToken, isNull);
    mock.close();
  });
  test('created order uses the fee confirmed by the backend', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/order');
      expect(request.method, 'POST');
      final sent = jsonDecode(request.body);
      expect(sent['weightKg'], 2);
      expect(sent['deliveryAddress'], 'Delivery');
      return http.Response(
        jsonEncode({
          'maDh': 'order-1',
          'maKh': 'customer-1',
          'trangThai': 'PENDING',
          'diaChiLay': 'Pickup',
          'diaChiGiao': 'Delivery',
          'phiGiaoHang': 35000,
          'tienCod': 100,
          'khoiLuong': 2,
        }),
        201,
      );
    });
    final orders = OrdersApi(client: ApiClient(client: mock));
    final result = await orders.create(
      const CreateOrderRequest(
        customerId: 'customer-1',
        receiverName: 'Receiver',
        receiverPhone: '0900000001',
        pickupAddress: 'Pickup',
        deliveryAddress: 'Delivery',
        weightKg: 2,
        codAmount: 100,
        shippingFee: 1,
      ),
    );
    expect(result?.shippingFee, 35000);
    expect(result?.status, 'PENDING');
    mock.close();
  });
  test(
    'legacy profile without token cannot restore a signed-in session',
    () async {
      SharedPreferences.setMockInitialValues({'customer_id': 'c-1'});
      expect(await sessionStore.restore(), isFalse);
    },
  );
  test('restored token is attached and logout removes it', () async {
    final savedToken =
        'header.${base64Url.encode(utf8.encode(jsonEncode({'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000})))}.signature';
    SharedPreferences.setMockInitialValues({
      'customer_id': 'c-1',
      'customer_access_token': savedToken,
    });
    expect(await sessionStore.restore(), isTrue);
    expect(apiClient.accessToken, savedToken);
    await sessionStore.clear();
    expect(apiClient.accessToken, isNull);
    expect(
      (await SharedPreferences.getInstance()).getString(
        'customer_access_token',
      ),
      isNull,
    );
    appState.value = AppState();
  });
}
