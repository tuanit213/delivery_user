import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:userapp/core/network/api_client.dart';
import 'package:userapp/features/orders/presentation/order_actions.dart';

void main() {
  testWidgets(
    'pending order cancellation calls the backend and refreshes detail',
    (tester) async {
      var refreshed = 0, calls = 0;
      final client = ApiClient(
        client: MockClient((request) async {
          calls++;
          expect(request.method, 'PATCH');
          expect(request.url.path, '/api/order/order-1/status');
          expect(jsonDecode(request.body), 'CANCELLED');
          return http.Response('{}', 200);
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderActions(
              orderId: 'order-1',
              status: 'PENDING',
              client: client,
              onChanged: () => refreshed++,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Hủy đơn'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      await tester.tap(find.widgetWithText(FilledButton, 'Hủy đơn'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(refreshed, 1);
    },
  );
  testWidgets(
    'delivery code is displayed with its recipient safety instruction',
    (tester) async {
      var calls = 0;
      final client = ApiClient(
        client: MockClient((request) async {
          calls++;
          expect(request.url.path, '/api/delivery/order-2/otp');
          return http.Response(
            jsonEncode({'code': '123456', 'expiresAt': '2027-01-01T00:00:00Z'}),
            200,
          );
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderActions(
              orderId: 'order-2',
              status: 'DELIVERING',
              client: client,
              onChanged: () {},
            ),
          ),
        ),
      );
      await tester.tap(find.text('Lấy mã nhận hàng'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.text('123456'), findsOneWidget);
      expect(
        find.text('Hết hạn: 07:00 01/01/2027 (giờ Việt Nam)'),
        findsOneWidget,
      );
      expect(find.textContaining('không gửi SMS'), findsOneWidget);
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
    },
  );
}
