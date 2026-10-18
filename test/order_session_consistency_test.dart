import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:userapp/core/network/api_client.dart';
import 'package:userapp/features/auth/data/auth_api.dart';
import 'package:userapp/features/orders/data/orders_api.dart';

http.Response orders(String id) => http.Response(
  jsonEncode([
    {'maDh': id, 'maKh': 'c1', 'trangThai': 'PENDING'},
  ]),
  200,
);

void main() {
  test('successful response from an old session is rejected', () async {
    final reply = Completer<http.Response>();
    final client = ApiClient(client: MockClient((_) => reply.future));
    client.setAccessToken('old');
    final pending = client.get('/api/order');
    final assertion = expectLater(
      pending,
      throwsA(isA<SessionChangedException>()),
    );
    client.setAccessToken('new');
    reply.complete(orders('old-order'));
    await assertion;
    expect(client.accessToken, 'new');
  });

  test(
    'logout and reusing the same token still invalidates old work',
    () async {
      final reply = Completer<http.Response>();
      final client = ApiClient(client: MockClient((_) => reply.future));
      client.setAccessToken('same-token');
      final pending = client.get('/api/order');
      final assertion = expectLater(
        pending,
        throwsA(isA<SessionChangedException>()),
      );
      client.setAccessToken(null);
      client.setAccessToken('same-token');
      reply.complete(orders('old-order'));
      await assertion;
    },
  );

  test('a cache clear cannot be undone by a pending response', () async {
    final reply = Completer<http.Response>();
    var calls = 0;
    final api = OrdersApi(
      client: ApiClient(
        client: MockClient((_) {
          calls++;
          return calls == 1
              ? reply.future
              : Future.value(orders('fresh-order'));
        }),
      ),
    );
    final pending = api.forCustomer('c1');
    final assertion = expectLater(
      pending,
      throwsA(isA<SessionChangedException>()),
    );
    api.clearCache();
    reply.complete(orders('old-order'));
    await assertion;
    expect((await api.forCustomer('c1')).single.id, 'fresh-order');
    expect(calls, 2);
  });

  test('an older forced refresh does not overwrite a newer cache', () async {
    final first = Completer<http.Response>(),
        second = Completer<http.Response>();
    var calls = 0;
    final api = OrdersApi(
      client: ApiClient(
        client: MockClient((_) {
          return ++calls == 1 ? first.future : second.future;
        }),
      ),
    );
    final old = api.forCustomer('c1', forceRefresh: true);
    final fresh = api.forCustomer('c1', forceRefresh: true);
    second.complete(orders('fresh-order'));
    await fresh;
    first.complete(orders('old-order'));
    await old;
    expect((await api.forCustomer('c1')).single.id, 'fresh-order');
    expect(calls, 2);
  });

  test('an old completion cannot remove the new in-flight request', () async {
    final first = Completer<http.Response>(),
        second = Completer<http.Response>();
    var calls = 0;
    final api = OrdersApi(
      client: ApiClient(
        client: MockClient((_) {
          return ++calls == 1 ? first.future : second.future;
        }),
      ),
    );
    final old = api.forCustomer('c1');
    final assertion = expectLater(old, throwsA(isA<SessionChangedException>()));
    api.clearCache();
    final fresh = api.forCustomer('c1');
    first.complete(orders('old-order'));
    await assertion;
    expect(identical(api.forCustomer('c1'), fresh), isTrue);
    second.complete(orders('fresh-order'));
    await fresh;
    expect(calls, 2);
  });

  test('an older failed login does not clear a newer session', () async {
    final profile = Completer<http.Response>();
    final requestedProfile = Completer<void>();
    final client = ApiClient(
      client: MockClient((request) {
        if (request.url.path.endsWith('/login')) {
          return Future.value(
            http.Response('{"accessToken":"old-login"}', 200),
          );
        }
        requestedProfile.complete();
        return profile.future;
      }),
    );
    final pending = AuthApi(
      client: client,
    ).login(username: 'old', password: 'password');
    final assertion = expectLater(
      pending,
      throwsA(isA<SessionChangedException>()),
    );
    await requestedProfile.future;
    client.setAccessToken('new-login');
    profile.complete(http.Response('{"role":"ADMIN"}', 200));
    await assertion;
    expect(client.accessToken, 'new-login');
  });
}
