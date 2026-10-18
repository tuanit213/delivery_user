import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:userapp/core/network/api_client.dart';
import 'package:userapp/core/state/app_state.dart';
import 'package:userapp/features/home/presentation/home_screen.dart';
import 'package:userapp/features/orders/data/orders_api.dart';
import 'package:userapp/features/orders/presentation/order_actions.dart';
import 'package:userapp/features/orders/presentation/order_flow_screens.dart';
import 'package:userapp/shared/widgets/refresh_notice.dart';

CustomerOrder order(String id, {String status = 'DELIVERING'}) => CustomerOrder(
  id: id,
  status: status,
  pickupAddress: 'Điểm lấy QA',
  deliveryAddress: 'Điểm giao QA',
  codAmount: 42000,
  shippingFee: 20000,
);
OrderDetailData detail(String id) =>
    OrderDetailData(order: order(id), history: const []);

class FakeOrdersApi extends OrdersApi {
  Future<List<CustomerOrder>> Function() list = () async => [order('order-a')];
  Future<OrderDetailData?> Function(String) read = (id) async => detail(id);

  @override
  Future<List<CustomerOrder>> forCustomer(
    String id, {
    bool forceRefresh = false,
  }) => list();
  @override
  Future<OrderDetailData?> detailById(String id) => read(id);
}

void main() {
  setUp(() => appState.value = AppState(customerId: 'customer-a'));
  tearDown(() => appState.value = AppState());

  for (final screen in ['Home', 'Orders']) {
    testWidgets(
      '$screen retains data with a stale notice and recovers through retry',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var offline = false;
        final api = FakeOrdersApi()
          ..list = () async {
            if (offline) throw StateError('offline');
            return [order('order-a')];
          };
        await tester.pumpWidget(
          MaterialApp(
            home: screen == 'Home'
                ? HomeScreen(api: api)
                : OrdersScreen(api: api),
          ),
        );
        await tester.pump();
        expect(find.byType(RefreshNotice), findsNothing);
        offline = true;
        await tester.pump(const Duration(seconds: 5));
        await tester.pump();
        expect(find.byType(RefreshNotice), findsOneWidget);
        expect(find.textContaining('lần tải thành công'), findsOneWidget);
        offline = false;
        await tester.tap(find.text('Thử lại'));
        await tester.pump();
        expect(find.byType(RefreshNotice), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'detail outage keeps the snapshot but disables writes until retry succeeds',
    (tester) async {
      var offline = false;
      final api = FakeOrdersApi()
        ..read = (id) async {
          if (offline) throw const ApiException(503, '');
          return detail(id);
        };
      await tester.pumpWidget(
        MaterialApp(
          home: StatusScreen(orderId: 'order-a', api: api),
        ),
      );
      await tester.pump();
      expect(
        tester.widget<OrderActions>(find.byType(OrderActions)).enabled,
        isTrue,
      );
      offline = true;
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(find.text('Mã đơn: order-a'), findsOneWidget);
      expect(find.byType(RefreshNotice), findsOneWidget);
      expect(
        tester.widget<OrderActions>(find.byType(OrderActions)).enabled,
        isFalse,
      );
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Lấy mã nhận hàng'),
      );
      expect(button.onPressed, isNull);
      offline = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      expect(
        tester.widget<OrderActions>(find.byType(OrderActions)).enabled,
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('deleted detail removes the old order and its actions', (
    tester,
  ) async {
    var removed = false;
    final api = FakeOrdersApi()
      ..read = (id) async => removed ? null : detail(id);
    await tester.pumpWidget(
      MaterialApp(
        home: StatusScreen(orderId: 'order-a', api: api),
      ),
    );
    await tester.pump();
    removed = true;
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(find.byType(OrderActions), findsNothing);
    expect(find.text('Mã đơn: order-a'), findsNothing);
    expect(find.text('Không tìm thấy đơn hàng.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'changing detail id clears the previous view and rejects its late poll',
    (tester) async {
      final oldPoll = Completer<OrderDetailData?>(),
          next = Completer<OrderDetailData?>();
      var delayed = false;
      final api = FakeOrdersApi()
        ..read = (id) {
          if (id == 'order-b') return next.future;
          return delayed ? oldPoll.future : Future.value(detail(id));
        };
      await tester.pumpWidget(
        MaterialApp(
          home: StatusScreen(orderId: 'order-a', api: api),
        ),
      );
      await tester.pump();
      delayed = true;
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(
        MaterialApp(
          home: StatusScreen(orderId: 'order-b', api: api),
        ),
      );
      expect(find.text('Mã đơn: order-a'), findsNothing);
      oldPoll.complete(detail('order-a'));
      await tester.pump();
      expect(find.text('Mã đơn: order-a'), findsNothing);
      next.complete(detail('order-b'));
      await tester.pump();
      expect(find.text('Mã đơn: order-b'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'first load failure presents retry instead of an empty success state',
    (tester) async {
      var offline = true;
      final api = FakeOrdersApi()
        ..list = () async {
          if (offline) throw StateError('offline');
          return [];
        };
      await tester.pumpWidget(MaterialApp(home: OrdersScreen(api: api)));
      await tester.pump();
      expect(find.text('Bạn chưa có đơn hàng nào.'), findsNothing);
      offline = false;
      await tester.tap(find.text('Tải lại'));
      await tester.pump();
      expect(find.text('Bạn chưa có đơn hàng nào.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final width in [320.0, 390.0, 1280.0]) {
    for (final screen in ['Home', 'Orders', 'Status']) {
      testWidgets('$screen fits a $width pixel viewport', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = FakeOrdersApi();
        await tester.pumpWidget(
          MaterialApp(
            home: switch (screen) {
              'Home' => HomeScreen(api: api),
              'Orders' => OrdersScreen(api: api),
              _ => StatusScreen(orderId: 'order-a', api: api),
            },
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  for (final screen in ['Home', 'Orders', 'Status']) {
    testWidgets('$screen supports doubled text at phone width', (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const id = '0527be9b-2920-460d-8f1b-56a945412345';
      final api = FakeOrdersApi()..list = () async => [order(id)];
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: switch (screen) {
            'Home' => HomeScreen(api: api),
            'Orders' => OrdersScreen(api: api),
            _ => StatusScreen(orderId: id, api: api),
          },
        ),
      );
      await tester.pump();
      if (screen == 'Home') {
        await tester.drag(find.byType(ListView).first, const Offset(0, -900));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
