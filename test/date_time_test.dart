import 'package:flutter_test/flutter_test.dart';
import 'package:userapp/core/utils/date_time_utils.dart';

void main() {
  test(
    'UTC timestamps display Vietnam time consistently with or without Z',
    () {
      for (final value in ['2026-10-15T15:00:00Z', '2026-10-15T15:00:00']) {
        expect(vietnamTime(value)?.hour, 22);
        expect(vietnamTime(value)?.day, 15);
      }
      expect(vietnamTime('2026-10-15T21:00:00Z')?.day, 16);
      expect(vietnamTime('2026-10-15T21:00:00Z')?.hour, 4);
      expect(vietnamTime('2026-10-15T22:00:00+07:00')?.hour, 22);
      expect(vietnamTime('invalid'), isNull);
    },
  );
}
