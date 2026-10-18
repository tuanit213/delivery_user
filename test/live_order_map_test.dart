import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:userapp/core/network/api_client.dart';
import 'package:userapp/features/orders/presentation/live_order_map.dart';

class OfflineTiles extends TileProvider {
  @override
  ImageProvider getImage(
    TileCoordinates coordinates,
    TileLayer options,
  ) => MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==',
    ),
  );
}

void main() {
  testWidgets(
    'GPS refresh preserves the map and the camera chosen by the user',
    (tester) async {
      var latitude = 10.0;
      final client = ApiClient(
        client: MockClient(
          (r) async => http.Response(
            jsonEncode(
              r.url.path.startsWith('/api/order/')
                  ? {'maSp': 'driver', 'trangThai': 'DELIVERING'}
                  : {
                      'name': 'QA driver',
                      'latitude': latitude,
                      'longitude': 106,
                    },
            ),
            200,
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: LiveOrderMap(
            orderId: 'a',
            client: client,
            tileProvider: OfflineTiles(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final original = tester.state(find.byType(FlutterMap));
      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      map.mapController!.move(const LatLng(11, 107), 12);
      map.options.onPositionChanged!(map.mapController!.camera, true);
      await tester.pump();
      latitude = 10.1;
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(FlutterMap)), same(original));
      expect(map.mapController!.camera.zoom, 12);
      expect(map.mapController!.camera.center.latitude, closeTo(11, 0.001));
      expect(find.text('Theo tài xế'), findsOneWidget);
      await tester.tap(find.text('Theo tài xế'));
      await tester.pumpAndSettle();
      expect(map.mapController!.camera.center.latitude, closeTo(10.1, 0.001));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('access loss removes the previous driver and the map', (
    tester,
  ) async {
    var denied = false;
    final client = ApiClient(
      client: MockClient(
        (r) async => http.Response(
          jsonEncode(
            r.url.path.startsWith('/api/order/')
                ? {'maSp': 'driver', 'trangThai': 'DELIVERING'}
                : {'name': 'Private driver', 'latitude': 10, 'longitude': 106},
          ),
          denied ? 403 : 200,
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: LiveOrderMap(
          orderId: 'a',
          client: client,
          tileProvider: OfflineTiles(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Private driver'), findsOneWidget);
    denied = true;
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Private driver'), findsNothing);
    expect(find.byType(FlutterMap), findsNothing);
    expect(find.textContaining('Không thể tải vị trí'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
