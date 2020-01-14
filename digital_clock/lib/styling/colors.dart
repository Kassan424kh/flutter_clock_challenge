import 'package:flutter/material.dart';

enum ElementColor {
  primary,
  hour,
  minute,
  centerShadow,
  date
}

class ClockColorThemes {
  static final lightTheme = {
    ElementColor.primary: Colors.white,
    ElementColor.hour: [
      Color(0xff002fff),
      Color(0xff00f4ff),
    ],
    ElementColor.minute: [
      Color(0xff4B00FF),
      Color(0xffff00d9),
    ],
    ElementColor.centerShadow: Color(0xff6F0FFF).withOpacity(0.3),
    ElementColor.date: Color(0xff6F0FFF)
  };
  static final darkTheme = {
    ElementColor.primary: Color(0xff0a0060),
    ElementColor.hour: [
      Color(0xff002fff),
      Color(0xff00f4ff),
    ],
    ElementColor.minute: [
      Color(0xff4B00FF),
      Color(0xffff00d9),
    ],
    ElementColor.centerShadow: Color(0xff6F0FFF).withOpacity(0.5),
    ElementColor.date: Color(0xff6F0FFF)
  };
}