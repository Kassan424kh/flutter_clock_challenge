import 'package:flutter/material.dart';

class DataOfClockNumbers with ChangeNotifier {
  Offset activeMinuteNumberOffset = Offset(0, 0);
  setActiveMinuteNumberOffset(Offset o) {
    activeMinuteNumberOffset = o;
    notifyListeners();
  }
}
