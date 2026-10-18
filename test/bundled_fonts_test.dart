import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'all customer font variants and licenses ship in the app bundle',
    () async {
      const families = {
        'BeVietnamPro': [
          'Thin',
          'ExtraLight',
          'Light',
          'Regular',
          'Medium',
          'SemiBold',
          'Bold',
          'ExtraBold',
          'Black',
        ],
        'IBMPlexMono': ['Regular', 'Medium', 'SemiBold', 'Bold'],
        'VT323': ['Regular'],
      };
      for (final family in families.entries) {
        for (final weight in family.value) {
          final asset = 'assets/fonts/${family.key}-$weight.ttf';
          final bytes = await rootBundle.load(asset);
          expect(bytes.lengthInBytes, greaterThan(1000), reason: asset);
          expect(bytes.getUint32(0), 0x00010000, reason: asset);
        }
        final license = await rootBundle.loadString(
          'assets/font_licenses/${family.key}-OFL.txt',
        );
        expect(license, contains('SIL OPEN FONT LICENSE'));
      }
    },
  );
}
