import 'package:flutter_test/flutter_test.dart';
import 'package:userapp/features/orders/data/orders_api.dart';
import 'package:userapp/features/orders/data/peak_hour_model.dart';
import 'package:userapp/features/orders/data/shipping_quote_model.dart';
import 'package:userapp/core/network/api_client.dart';

void main() {
  group('Shipping quotes', () {
    test(
      'rejects missing or invalid fees instead of accepting free delivery',
      () {
        for (final fee in [null, 'invalid', -1, double.nan, double.infinity]) {
          expect(
            () => ShippingQuote.fromJson({'shippingFee': fee}),
            throwsFormatException,
          );
        }
      },
    );

    test('accepts a server-confirmed zero fee and parses numeric strings', () {
      final quote = ShippingQuote.fromJson({
        'shippingFee': '0',
        'distanceKm': '2.5',
        'durationMinutes': 12,
      });
      expect(quote.shippingFee, 0);
      expect(quote.distanceKm, 2.5);
      expect(quote.durationMinutes, 12);
    });
  });

  test(
    'PascalCase peak-hour settings apply across midnight and week boundary',
    () {
      final config = PeakHourConfig.fromJson({
        'IsActive': true,
        'CacNgayApDung': '0000001', // Sunday only.
        'GioBatDau': '22:00:00',
        'GioKetThuc': '05:00:00',
        'HeSoPhi': 1.5,
      });
      expect(config.isActiveAt(DateTime(2026, 10, 18, 23)), isTrue);
      expect(config.isActiveAt(DateTime(2026, 10, 19, 4)), isTrue);
      expect(config.isActiveAt(DateTime(2026, 10, 19, 6)), isFalse);
      expect(config.isActiveAt(DateTime(2026, 10, 19, 23)), isFalse);
    },
  );

  test('completed and cancelled orders are not counted as active', () {
    for (final status in ['HOAN_THANH', 'HoanThanh', 'hoan-thanh', 'DA_GIAO']) {
      expect(isCustomerOrderCompleted(status), isTrue);
      expect(isCustomerOrderActive(status), isFalse);
    }
    expect(isCustomerOrderCompleted('DA_HUY'), isFalse);
    expect(isCustomerOrderActive('DA_HUY'), isFalse);
    expect(isCustomerOrderActive('CHO_XAC_NHAN'), isTrue);
  });

  test('offline tunnel errors explain the failure without rendering HTML', () {
    expect(
      const ApiException(404, '<html>ERR_NGROK_3200</html>').toString(),
      contains('ngoại tuyến'),
    );
    expect(
      const ApiException(500, '<html>error</html>').toString(),
      isNot(contains('<html>')),
    );
    expect(
      const ApiException(
        400,
        '{"message":"Thông tin không hợp lệ"}',
      ).toString(),
      'Thông tin không hợp lệ',
    );
  });
}
