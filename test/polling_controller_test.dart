import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:userapp/core/network/api_client.dart';
import 'package:userapp/core/state/polling_controller.dart';

void main() {
  test(
    'retains the last snapshot during an outage and clears error on recovery',
    () async {
      var offline = false;
      final controller = PollingController(() async {
        if (offline) throw StateError('offline');
        return 'current';
      });
      addTearDown(controller.dispose);
      await controller.refresh();
      final updated = controller.updatedAt;
      offline = true;
      await controller.refresh();
      expect(controller.data, 'current');
      expect(controller.updatedAt, updated);
      expect(controller.error, isA<StateError>());
      offline = false;
      await controller.refresh();
      expect(controller.error, isNull);
      expect(controller.isRefreshing, isFalse);
    },
  );

  test('late success cannot overwrite a newer manual refresh', () async {
    final old = Completer<String>(), fresh = Completer<String>();
    var calls = 0;
    final controller = PollingController(
      () => ++calls == 1 ? old.future : fresh.future,
    );
    addTearDown(controller.dispose);
    final first = controller.refresh(), second = controller.refresh();
    fresh.complete('new');
    await second;
    old.complete('old');
    await first;
    expect(controller.data, 'new');
  });

  test('late error cannot replace a successful newer response', () async {
    final old = Completer<String>();
    var calls = 0;
    final controller = PollingController(
      () => ++calls == 1 ? old.future : Future.value('new'),
    );
    addTearDown(controller.dispose);
    final first = controller.refresh();
    await controller.refresh();
    old.completeError(StateError('late failure'));
    await first;
    expect(controller.data, 'new');
    expect(controller.error, isNull);
  });

  test(
    'an old completion cannot mark a newer in-flight refresh finished',
    () async {
      final old = Completer<String>(), fresh = Completer<String>();
      var calls = 0;
      final controller = PollingController(
        () => ++calls == 1 ? old.future : fresh.future,
      );
      addTearDown(controller.dispose);
      final first = controller.refresh(), second = controller.refresh();
      old.complete('old');
      await first;
      expect(controller.isRefreshing, isTrue);
      fresh.complete('new');
      await second;
      expect(controller.isRefreshing, isFalse);
    },
  );

  for (final status in [401, 403, 404]) {
    test('HTTP $status removes previously actionable data', () async {
      var unavailable = false;
      final controller = PollingController(() async {
        if (unavailable) throw ApiException(status, '');
        return 'private order';
      });
      addTearDown(controller.dispose);
      await controller.refresh();
      unavailable = true;
      await controller.refresh();
      expect(controller.data, isNull);
      expect(controller.updatedAt, isNull);
    });
  }

  test('a changed session removes the previous snapshot', () async {
    var changed = false;
    final controller = PollingController(() async {
      if (changed) throw const SessionChangedException();
      return 'private order';
    });
    addTearDown(controller.dispose);
    await controller.refresh();
    changed = true;
    await controller.refresh();
    expect(controller.data, isNull);
  });

  test('synchronous loader errors release loading state', () async {
    final controller = PollingController<String>(
      () => throw StateError('sync failure'),
    );
    addTearDown(controller.dispose);
    await controller.refresh();
    expect(controller.isRefreshing, isFalse);
    expect(controller.error, isA<StateError>());
  });

  test(
    'disposed controller ignores a pending response and future refresh calls',
    () async {
      final pending = Completer<String>();
      var calls = 0, notifications = 0;
      final controller = PollingController(() {
        calls++;
        return pending.future;
      });
      controller.addListener(() => notifications++);
      final request = controller.refresh();
      controller.dispose();
      pending.complete('late');
      await request;
      await controller.refresh();
      expect(controller.data, isNull);
      expect(calls, 1);
      expect(notifications, 1);
    },
  );

  testWidgets('timer skips overlapping requests and is cancelled on dispose', (
    tester,
  ) async {
    final pending = Completer<String>();
    var calls = 0;
    final controller = PollingController(() {
      calls++;
      return pending.future;
    });
    controller.start();
    controller.start();
    await tester.pump(const Duration(seconds: 15));
    expect(calls, 1);
    pending.complete('ready');
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(calls, 2);
    controller.dispose();
    await tester.pump(const Duration(seconds: 10));
    expect(calls, 2);
  });
}
