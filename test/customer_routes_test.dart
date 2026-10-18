import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:userapp/core/state/app_state.dart';
import 'package:userapp/features/customer/presentation/customer_app.dart';

void main() {
  tearDown(() => appState.value = AppState());

  testWidgets('protected deep link redirects a signed-out customer to login', (
    tester,
  ) async {
    appState.value = AppState();
    final router = createCustomerRouter();
    addTearDown(router.dispose);
    late Future<dynamic> parsed;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            parsed = router.routeInformationParser
                .parseRouteInformationWithDependencies(
                  RouteInformation(uri: Uri.parse('/orders/test-order/status')),
                  context,
                );
            return const SizedBox();
          },
        ),
      ),
    );
    final matches = await parsed;
    expect(matches.uri.path, '/login');
  });

  testWidgets('a signed-in customer opening login is redirected to home', (
    tester,
  ) async {
    appState.value = AppState(customerId: 'customer-1');
    final router = createCustomerRouter();
    addTearDown(router.dispose);
    late Future<dynamic> parsed;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            parsed = router.routeInformationParser
                .parseRouteInformationWithDependencies(
                  RouteInformation(uri: Uri.parse('/login')),
                  context,
                );
            return const SizedBox();
          },
        ),
      ),
    );
    final matches = await parsed;
    expect(matches.uri.path, '/home');
  });
}
