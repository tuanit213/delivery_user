import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:userapp/features/orders/presentation/confirmation_screen.dart';
import 'package:userapp/shared/widgets/pixel_order_scene.dart';

void main() {
  Future<GoRouter> showConfirmation(WidgetTester tester, String? id) async {
    final router = GoRouter(
      initialLocation: '/confirmation',
      routes: [
        GoRoute(
          path: '/confirmation',
          builder: (_, _) => ConfirmationScreen(orderId: id),
        ),
        GoRoute(
          path: '/orders',
          builder: (_, _) => const Scaffold(body: Text('Order list')),
        ),
        GoRoute(
          path: '/orders/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Order ${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (_, child) => MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: child!,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('direct confirmation without an order does not claim success', (
    tester,
  ) async {
    final router = await showConfirmation(tester, null);
    expect(find.text('Đặt hàng thành công!'), findsNothing);
    expect(find.byType(PixelOrderScene), findsNothing);
    await tester.tap(find.text('Xem đơn hàng'));
    await tester.pumpAndSettle();
    expect(find.text('Order list'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
  });

  testWidgets('confirmed order shows success animation and opens that order', (
    tester,
  ) async {
    final router = await showConfirmation(tester, 'QA-123');
    expect(find.text('Đặt hàng thành công!'), findsOneWidget);
    expect(find.text('Mã đơn: QA-123'), findsOneWidget);
    expect(
      tester.widget<PixelOrderScene>(find.byType(PixelOrderScene)).confirmed,
      isTrue,
    );
    await tester.ensureVisible(find.text('Xem đơn hàng'));
    await tester.tap(find.text('Xem đơn hàng'));
    await tester.pumpAndSettle();
    expect(find.text('Order QA-123'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
  });

  testWidgets('success screen returns home', (tester) async {
    final router = await showConfirmation(tester, 'QA-123');
    await tester.ensureVisible(find.text('Về trang chủ'));
    await tester.tap(find.text('Về trang chủ'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
  });
}
