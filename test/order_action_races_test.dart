import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:userapp/core/network/api_client.dart';
import 'package:userapp/features/orders/presentation/order_actions.dart';

void main() {
  Widget app(
    ApiClient client,
    String id, {
    String status = 'PENDING',
    VoidCallback? changed,
  }) => MaterialApp(
    home: Scaffold(
      body: OrderActions(
        orderId: id,
        status: status,
        client: client,
        onChanged: changed ?? () {},
      ),
    ),
  );

  testWidgets(
    'changing order during confirmation dismisses it without cancelling either order',
    (tester) async {
      var calls = 0;
      final client = ApiClient(
        client: MockClient((_) async {
          calls++;
          return http.Response('{}', 200);
        }),
      );
      await tester.pumpWidget(app(client, 'old'));
      await tester.tap(find.text('Hủy đơn'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(app(client, 'new'));
      await tester.pumpAndSettle();
      expect(find.text('Hủy đơn hàng?'), findsNothing);
      expect(calls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('double tap opens only one cancellation confirmation', (
    tester,
  ) async {
    final client = ApiClient(
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    await tester.pumpWidget(app(client, 'a'));
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    button.onPressed!();
    button.onPressed!();
    await tester.pumpAndSettle();
    expect(find.text('Hủy đơn hàng?'), findsOneWidget);
    await tester.tap(find.text('Giữ đơn'));
    await tester.pumpAndSettle();
  });

  testWidgets('unmounting while confirmation is open is safe', (tester) async {
    final client = ApiClient(
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    await tester.pumpWidget(app(client, 'a'));
    await tester.tap(find.text('Hủy đơn'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final changeSession in [false, true]) {
    testWidgets(
      'late OTP is hidden after ${changeSession ? 'session' : 'order'} changes',
      (tester) async {
        final reply = Completer<http.Response>();
        final client = ApiClient(client: MockClient((_) => reply.future));
        client.setAccessToken('old');
        await tester.pumpWidget(app(client, 'a', status: 'DELIVERING'));
        await tester.tap(find.text('Lấy mã nhận hàng'));
        await tester.pump();
        if (changeSession) {
          client.setAccessToken('new');
        } else {
          await tester.pumpWidget(app(client, 'b', status: 'DELIVERING'));
        }
        reply.complete(
          http.Response(
            jsonEncode({'code': '123456', 'expiresAt': '2027-01-01T00:00:00Z'}),
            200,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('123456'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('malformed receiving code cannot appear as a valid OTP', (
    tester,
  ) async {
    final client = ApiClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'expiresAt': '2027-01-01T00:00:00Z'}),
          200,
        ),
      ),
    );
    await tester.pumpWidget(app(client, 'a', status: 'DELIVERING'));
    await tester.tap(find.text('Lấy mã nhận hàng'));
    await tester.pumpAndSettle();
    expect(find.text('Mã xác nhận nhận hàng'), findsNothing);
    expect(find.textContaining('Mã nhận hàng không hợp lệ'), findsOneWidget);
  });

  testWidgets('visible OTP closes when the session changes', (tester) async {
    final client = ApiClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'code': '123456', 'expiresAt': '2027-01-01T00:00:00Z'}),
          200,
        ),
      ),
    );
    client.setAccessToken('old');
    await tester.pumpWidget(app(client, 'a', status: 'DELIVERING'));
    await tester.tap(find.text('Lấy mã nhận hàng'));
    await tester.pumpAndSettle();
    expect(find.text('123456'), findsOneWidget);
    client.setAccessToken('new');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('123456'), findsNothing);
  });
}
