import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:userapp/core/network/api_client.dart';
import 'package:userapp/features/orders/data/orders_api.dart';

Map<String, dynamic> order(String status) => {
  'maDh': 'order-a',
  'maKh': 'customer-a',
  'trangThai': status,
};
http.Response json(Object? value, [int status = 200]) =>
    http.Response(jsonEncode(value), status);

void main() {
  for (final invalid in <Map<String, dynamic>>[
    {},
    {'maDh': 'another-order'},
  ]) {
    test(
      'rejects a response with a missing or mismatched order ID: $invalid',
      () async {
        final api = OrdersApi(
          client: ApiClient(client: MockClient((_) async => json(invalid))),
        );
        await expectLater(api.detailById('order-a'), throwsFormatException);
      },
    );
  }

  for (final failure in ['order', 'history', 'proof']) {
    test(
      '$failure outage cannot return cached detail as a fresh success',
      () async {
        final api = OrdersApi(
          client: ApiClient(
            client: MockClient((request) async {
              final path = request.url.path;
              if (path == '/api/order') return json([order('PENDING')]);
              if (failure == 'order' && path == '/api/order/order-a' ||
                  failure == 'history' && path.endsWith('/history') ||
                  failure == 'proof' && path.endsWith('/proof')) {
                return json({'message': 'QA unavailable'}, 503);
              }
              if (path.endsWith('/history')) return json([]);
              if (path.endsWith('/proof')) return http.Response('', 204);
              return json(order('DELIVERING'));
            }),
          ),
        );
        await api.forCustomer('customer-a');
        await expectLater(
          api.detailById('order-a'),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'status', 503),
          ),
        );
      },
    );
  }

  test(
    'deleted order returns null and is removed from the cached list',
    () async {
      final api = OrdersApi(
        client: ApiClient(
          client: MockClient(
            (request) async => request.url.path == '/api/order'
                ? json([order('PENDING')])
                : json({}, 404),
          ),
        ),
      );
      await api.forCustomer('customer-a');
      expect(await api.detailById('order-a'), isNull);
      expect(await api.forCustomer('customer-a'), isEmpty);
    },
  );

  test(
    'a malformed detail response is an error rather than a cached success',
    () async {
      final api = OrdersApi(
        client: ApiClient(
          client: MockClient(
            (request) async => request.url.path == '/api/order'
                ? json([order('PENDING')])
                : json('invalid'),
          ),
        ),
      );
      await api.forCustomer('customer-a');
      await expectLater(api.detailById('order-a'), throwsFormatException);
    },
  );

  test(
    'an old detail response cannot downgrade a newer cached status',
    () async {
      final first = Completer<http.Response>(),
          second = Completer<http.Response>();
      var reads = 0;
      final api = OrdersApi(
        client: ApiClient(
          client: MockClient((request) async {
            if (request.url.path == '/api/order') {
              return json([order('PENDING')]);
            }
            if (request.url.path.endsWith('/history')) {
              return json([]);
            }
            if (request.url.path.endsWith('/proof')) {
              return http.Response('', 204);
            }
            return ++reads == 1 ? first.future : second.future;
          }),
        ),
      );
      await api.forCustomer('customer-a');
      final old = api.detailById('order-a'), fresh = api.detailById('order-a');
      second.complete(json(order('DELIVERING')));
      await fresh;
      first.complete(json(order('PENDING')));
      await old;
      expect((await api.forCustomer('customer-a')).single.status, 'DELIVERING');
    },
  );

  test(
    'a missing proof endpoint does not pretend the order itself disappeared',
    () async {
      final api = OrdersApi(
        client: ApiClient(
          client: MockClient((request) async {
            if (request.url.path.endsWith('/history')) return json([]);
            if (request.url.path.endsWith('/proof')) return json({}, 404);
            return json(order('DELIVERING'));
          }),
        ),
      );
      await expectLater(
        api.detailById('order-a'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 404)),
      );
    },
  );
}
