import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:userapp/core/network/api_client.dart';
import 'package:userapp/features/orders/data/orders_api.dart';
import 'package:userapp/features/orders/presentation/order_flow_screens.dart';

class ProofApi extends OrdersApi {
  ProofApi(this.read);
  final Future<OrderDetailData?> Function(String id) read;
  @override
  Future<OrderDetailData?> detailById(String orderId) => read(orderId);
}

OrderDetailData detail(String id, {String? signature}) => OrderDetailData(
  order: CustomerOrder(
    id: id,
    status: 'COMPLETED',
    pickupAddress: 'QA',
    deliveryAddress: 'QA',
    codAmount: 0,
    shippingFee: 0,
  ),
  history: const [],
  proof: signature == null ? null : DeliveryProof(otpSignature: signature),
);

void main() {
  testWidgets('proof outage is distinct from no proof and can be retried', (
    tester,
  ) async {
    var failed = true, calls = 0;
    final api = ProofApi((id) async {
      calls++;
      if (failed) throw const ApiException(503, '');
      return detail(id);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: ProofScreen(orderId: 'a', api: api),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Không thể tải minh chứng'), findsOneWidget);
    expect(find.text('Đơn hàng chưa có minh chứng giao hàng.'), findsNothing);
    failed = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Đơn hàng chưa có minh chứng giao hàng.'), findsOneWidget);
  });
  testWidgets('missing order is not described as missing proof', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProofScreen(orderId: 'missing', api: ProofApi((_) async => null)),
      ),
    );
    await tester.pump();
    expect(find.text('Không tìm thấy đơn hàng.'), findsOneWidget);
    expect(find.text('Đơn hàng chưa có minh chứng giao hàng.'), findsNothing);
  });
  testWidgets('ordinary rebuild does not restart a proof request', (
    tester,
  ) async {
    var calls = 0;
    final api = ProofApi((id) async {
      calls++;
      return detail(id);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: ProofScreen(orderId: 'a', api: api),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: ProofScreen(orderId: 'a', api: api),
      ),
    );
    await tester.pump();
    expect(calls, 1);
  });
  testWidgets('changing order discards an older in-flight proof', (
    tester,
  ) async {
    final first = Completer<OrderDetailData?>(),
        second = Completer<OrderDetailData?>();
    final api = ProofApi((id) => id == 'a' ? first.future : second.future);
    await tester.pumpWidget(
      MaterialApp(
        home: ProofScreen(orderId: 'a', api: api),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProofScreen(orderId: 'b', api: api),
      ),
    );
    first.complete(detail('a', signature: 'Old proof'));
    await tester.pump();
    expect(find.text('Old proof'), findsNothing);
    second.complete(detail('b', signature: 'New proof'));
    await tester.pump();
    expect(find.text('New proof'), findsOneWidget);
  });
}
