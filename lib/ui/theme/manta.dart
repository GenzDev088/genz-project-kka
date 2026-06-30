import 'package:otax/ui/theme/types.dart';
import 'package:flutter/material.dart';

class MantaTheme implements ThemeItem {
  @override
  int get id => 11;

  @override
  bool get dev => false;

  @override
  AnimeStreamTheme get lightVariant => AnimeStreamTheme(
    accentColor: Color(0xFF00E5FF),
    backgroundColor: Color(0xfff5f9fc),
    modalSheetBackgroundColor: Color(0xffffffff),
    backgroundSubColor: Color(0xffe0eaf2),
    textMainColor: Color(0xff102a39),
    textSubColor: Color(0xff5d717f),
    onAccent: Colors.white,
  );

  @override
  String get name => "Manta";

  @override
  AnimeStreamTheme get theme => AnimeStreamTheme(
    accentColor: Color(0xFF00E5FF),
    backgroundColor: Color(0xFF030305),
    modalSheetBackgroundColor: Color(0xFF0A0A0C),
    backgroundSubColor: Color(0xFF121214),
    textMainColor: Color(0xffffffff),
    textSubColor: Color(0xffb0b8c1),
    onAccent: Colors.black,
  );
}
