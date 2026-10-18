import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:userapp/core/network/api_client.dart';
import 'package:userapp/core/state/polling_controller.dart';
import 'package:userapp/features/orders/data/driver_tracking_api.dart';

http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

void main() {
  test('GPS rejects non-numeric, non-finite and out-of-range coordinates', () {
    for (final pair in [
      [null, 1],
      ['10', 106],
      [double.nan, 1],
      [1, double.infinity],
      [91, 1],
      [1, -181],
    ]) {
      expect(trackingPosition(pair[0], pair[1]), isNull);
    }
    expect(trackingPosition(0, 0)?.latitude, 0);
    expect(trackingPosition(-90, 180)?.longitude, 180);
  });
  test('closed order never requests a driver location', () async {
    var calls = 0;
    final api = DriverTrackingApi(
      ApiClient(
        client: MockClient((_) async {
          calls++;
          return json({'maSp': 'driver', 'trangThai': 'COMPLETED'});
        }),
      ),
    );
    expect((await api.load('a')).driver, isNull);
    expect(calls, 1);
  });
  test(
    'completion during location lookup clears driver instead of reporting stale access error',
    () async {
      var orderReads = 0;
      final api = DriverTrackingApi(
        ApiClient(
          client: MockClient((r) async {
            if (r.url.path == '/api/order/a') {
              return json({
                'maSp': 'driver',
                'trangThai': ++orderReads == 1 ? 'DELIVERING' : 'COMPLETED',
              });
            }
            return json({}, 403);
          }),
        ),
      );
      final result = await api.load('a');
      expect(result.driver, isNull);
      expect(result.order['trangThai'], 'COMPLETED');
      expect(orderReads, 2);
    },
  );
  test(
    'reassignment during location lookup retries only for the new assigned driver',
    () async {
      var orderReads = 0;
      final paths = <String>[];
      final api = DriverTrackingApi(
        ApiClient(
          client: MockClient((r) async {
            paths.add(r.url.path);
            if (r.url.path == '/api/order/a') {
              return json({
                'maSp': ++orderReads == 1 ? 'old' : 'new',
                'trangThai': 'ASSIGNED',
              });
            }
            expect(r.url.queryParameters['orderId'], 'a');
            return r.url.path.contains('/old/')
                ? json({}, 404)
                : json({
                    'name': 'New driver',
                    'latitude': 10,
                    'longitude': 106,
                  });
          }),
        ),
      );
      final result = await api.load('a');
      expect(result.driver?['name'], 'New driver');
      expect(result.position?.latitude, 10);
      expect(paths.length, 4);
    },
  );
  test(
    'unchanged assignment propagates denial and clears previous tracking snapshot',
    () async {
      var denied = false;
      final api = DriverTrackingApi(
        ApiClient(
          client: MockClient((r) async {
            if (r.url.path == '/api/order/a') {
              return json({'maSp': 'd', 'trangThai': 'DELIVERING'});
            }
            return denied
                ? json({}, 403)
                : json({'name': 'Driver', 'latitude': 10, 'longitude': 106});
          }),
        ),
      );
      final state = PollingController(() => api.load('a'));
      addTearDown(state.dispose);
      await state.refresh();
      expect(state.data?.driver, isNotNull);
      denied = true;
      await state.refresh();
      expect(state.data, isNull);
      expect(state.error, isA<ApiException>());
    },
  );
  test(
    'temporary outage preserves the last snapshot with an explicit refresh error',
    () async {
      var failed = false;
      final api = DriverTrackingApi(
        ApiClient(
          client: MockClient((r) async {
            if (failed) return json({}, 503);
            return r.url.path == '/api/order/a'
                ? json({'maSp': 'd', 'trangThai': 'DELIVERING'})
                : json({'latitude': 10, 'longitude': 106});
          }),
        ),
      );
      final state = PollingController(() => api.load('a'));
      addTearDown(state.dispose);
      await state.refresh();
      final previous = state.data;
      failed = true;
      await state.refresh();
      expect(state.data, same(previous));
      expect(state.error, isNotNull);
    },
  );
}
