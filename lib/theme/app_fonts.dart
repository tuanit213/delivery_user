import 'package:flutter/material.dart';

abstract final class AppFonts {
  static const body = 'BeVietnamPro';
  static const mono = 'IBMPlexMono';
  static const pixel = 'VT323';

  static TextTheme textTheme() =>
      ThemeData.light().textTheme.apply(fontFamily: body);
}
