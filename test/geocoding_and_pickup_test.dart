import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:userapp/features/orders/data/geocoding_service.dart';
import 'package:userapp/features/profile/data/default_pickup_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const point = LatLng(10.7769, 106.7009);

  test(
    'reverse geocoding preserves Vietnamese address and removes duplicates',
    () async {
      final client = MockClient((r) async {
        expect(r.url.queryParameters['lat'], '10.7769');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'address': {
                'country_code': 'vn',
                'road': 'Đồng Khởi',
                'suburb': 'Bến Nghé',
                'state': 'Thành phố Hồ Chí Minh',
              },
            }),
          ),
          200,
        );
      });
      final address = await GeocodingService(
        client: client,
      ).reverseGeocode(point);
      expect(address, 'Đồng Khởi, Bến Nghé, TP. Hồ Chí Minh');
      client.close();
    },
  );

  test(
    'foreign location is rejected rather than using a fabricated Vietnamese address',
    () async {
      final client = MockClient(
        (_) async => http.Response(
          '{"address":{"country_code":"us","road":"Main Street"}}',
          200,
        ),
      );
      await expectLater(
        GeocodingService(client: client).reverseGeocode(point),
        throwsA(isA<GeocodingException>()),
      );
      client.close();
    },
  );

  test('invalid coordinates never call the geocoding provider', () async {
    final client = MockClient(
      (_) async => throw StateError('must not request'),
    );
    await expectLater(
      GeocodingService(client: client).reverseGeocode(const LatLng(91, 106)),
      throwsA(isA<GeocodingException>()),
    );
    client.close();
  });

  test(
    'network refusal becomes a readable error and does not leak a raw URL',
    () async {
      final client = MockClient(
        (_) async => throw http.ClientException(
          'Failed to fetch',
          Uri.parse('https://nominatim.openstreetmap.org/reverse'),
        ),
      );
      await expectLater(
        GeocodingService(client: client).reverseGeocode(point),
        throwsA(
          isA<GeocodingException>().having(
            (e) => e.message,
            'message',
            allOf(contains('kiểm tra mạng'), isNot(contains('https://'))),
          ),
        ),
      );
      client.close();
    },
  );

  test('provider errors do not become an empty success address', () async {
    final client = MockClient((_) async => http.Response('unavailable', 503));
    await expectLater(
      GeocodingService(client: client).reverseGeocode(point),
      throwsA(isA<GeocodingException>()),
    );
    client.close();
  });

  test(
    'default pickup persists per customer and clear does not affect another account',
    () async {
      SharedPreferences.setMockInitialValues({});
      const store = DefaultPickupStore();
      const pickup = DefaultPickupLocation(
        address: 'Địa chỉ QA',
        latitude: 10.7769,
        longitude: 106.7009,
      );
      await store.save('customer-a', pickup);
      expect((await store.load('customer-a'))?.address, pickup.address);
      expect((await store.load('customer-a'))?.latitude, pickup.latitude);
      expect(await store.load('customer-b'), isNull);
      await store.save('customer-b', pickup);
      await store.clear('customer-a');
      expect(await store.load('customer-a'), isNull);
      expect((await store.load('customer-b'))?.longitude, pickup.longitude);
    },
  );

  test(
    'default pickup rejects missing address and invalid coordinates',
    () async {
      SharedPreferences.setMockInitialValues({});
      await expectLater(
        defaultPickupStore.save(
          'qa',
          const DefaultPickupLocation(
            address: '',
            latitude: 10,
            longitude: 106,
          ),
        ),
        throwsArgumentError,
      );
      await expectLater(
        defaultPickupStore.save(
          'qa',
          const DefaultPickupLocation(
            address: 'QA',
            latitude: 91,
            longitude: 106,
          ),
        ),
        throwsArgumentError,
      );
      expect(await defaultPickupStore.load('qa'), isNull);
    },
  );
}
