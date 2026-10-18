import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:userapp/core/network/api_client.dart';
import 'package:userapp/core/state/app_state.dart';
import 'package:userapp/features/profile/data/default_pickup_store.dart';
import 'package:userapp/features/profile/presentation/edit_customer_profile_screen.dart';

const point = DefaultPickupLocation(
  address: 'QA pickup',
  latitude: 10.7,
  longitude: 106.7,
);

class PickupStore extends DefaultPickupStore {
  int saves = 0, clears = 0;
  bool failRead = false, failClear = false;
  Completer<void>? pending;
  @override
  Future<DefaultPickupLocation?> load(String customerId) async {
    if (failRead) throw StateError('Storage unavailable');
    return point;
  }

  @override
  Future<void> save(String customerId, DefaultPickupLocation location) async {
    saves++;
    await pending?.future;
  }

  @override
  Future<void> clear(String customerId) async {
    clears++;
    await pending?.future;
    if (failClear) throw StateError('Storage unavailable');
  }
}

void main() {
  Future<void> mount(WidgetTester tester, PickupStore store) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    appState.value = AppState(
      customerId: 'qa',
      name: 'QA Customer',
      phone: '0900000001',
    );
    addTearDown(() {
      appState.value = AppState();
      apiClient.setAccessToken(null);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: EditCustomerProfileScreen(
          customerId: 'qa',
          fullName: 'QA Customer',
          phone: '0900000001',
          email: '',
          address: '',
          pickupStore: store,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'save and clear are mutually exclusive and double clicks write once',
    (tester) async {
      final store = PickupStore()..pending = Completer<void>();
      await mount(tester, store);
      final save = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Lưu điểm'),
      );
      final clear = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Xóa điểm mặc định'),
      );
      save.onPressed!();
      save.onPressed!();
      clear.onPressed!();
      await tester.pump();
      expect(store.saves, 1);
      expect(store.clears, 0);
      expect(
        tester
            .widget<OutlinedButton>(find.byType(OutlinedButton).first)
            .onPressed,
        isNull,
      );
      store.pending!.complete();
      await tester.pumpAndSettle();
      expect(
        find.text('Đã lưu điểm lấy mặc định trên thiết bị.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('clear failure keeps the saved location and permits retry', (
    tester,
  ) async {
    final store = PickupStore()..failClear = true;
    await mount(tester, store);
    await tester.tap(find.text('Xóa điểm mặc định'));
    await tester.pumpAndSettle();
    expect(find.text('QA pickup'), findsOneWidget);
    expect(
      find.textContaining('Không thể xóa điểm lấy mặc định'),
      findsOneWidget,
    );
    store.failClear = false;
    await tester.tap(find.text('Xóa điểm mặc định'));
    await tester.pumpAndSettle();
    expect(store.clears, 2);
    expect(find.text('QA pickup'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('read failure offers a working retry', (tester) async {
    final store = PickupStore()..failRead = true;
    await mount(tester, store);
    expect(find.text('Thử lại điểm lấy'), findsOneWidget);
    store.failRead = false;
    await tester.tap(find.text('Thử lại điểm lấy'));
    await tester.pumpAndSettle();
    expect(find.text('QA pickup'), findsOneWidget);
    expect(find.text('Thử lại điểm lấy'), findsNothing);
  });

  testWidgets('old buttons cannot write after switching account', (
    tester,
  ) async {
    final store = PickupStore();
    await mount(tester, store);
    final save = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Lưu điểm'),
    );
    final clear = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Xóa điểm mặc định'),
    );
    apiClient.setAccessToken('changed-session');
    appState.value = AppState(customerId: 'other');
    save.onPressed!();
    clear.onPressed!();
    await tester.pumpAndSettle();
    expect(store.saves, 0);
    expect(store.clears, 0);
  });

  testWidgets('leaving during clear never updates a disposed screen', (
    tester,
  ) async {
    final store = PickupStore()..pending = Completer<void>();
    await mount(tester, store);
    tester
        .widget<TextButton>(
          find.widgetWithText(TextButton, 'Xóa điểm mặc định'),
        )
        .onPressed!();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    store.pending!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
