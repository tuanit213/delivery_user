import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:userapp/features/orders/data/geocoding_service.dart';

void main() {
  test('Photon response creates a Vietnamese pickup address', () async {
    final service = GeocodingService(
      client: MockClient((request) async {
        expect(request.url.host, 'photon.komoot.io');
        expect(request.url.path, '/reverse');
        expect(request.url.queryParameters['lat'], '10.7769');
        return http.Response(
          jsonEncode({
            'features': [
              {
                'properties': {
                  'countrycode': 'VN',
                  'name': 'Tòa nhà QA',
                  'housenumber': '12',
                  'street': 'Nguyễn Huệ',
                  'city': 'Thành phố Hồ Chí Minh',
                },
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    expect(
      await service.reverseGeocode(const LatLng(10.7769, 106.7009)),
      'Tòa nhà QA, 12 Nguyễn Huệ, TP. Hồ Chí Minh',
    );
  });
  test('Photon results outside Vietnam remain rejected', () async {
    final service = GeocodingService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'features': [
              {
                'properties': {'countrycode': 'DE', 'name': 'Berlin'},
              },
            ],
          }),
          200,
        ),
      ),
    );
    await expectLater(
      service.reverseGeocode(const LatLng(52, 13)),
      throwsA(isA<GeocodingException>()),
    );
  });
  test('Malformed geocoder response has a readable domain error', () async {
    final service = GeocodingService(
      client: MockClient(
        (_) async => http.Response('<html>unavailable</html>', 200),
      ),
    );
    await expectLater(
      service.reverseGeocode(const LatLng(10, 106)),
      throwsA(isA<GeocodingException>()),
    );
  });
}
