import 'dart:async';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import 'package:vector_math/vector_math_64.dart' show Quaternion, Vector3, Vector4, radians;
import 'package:provider/provider.dart';

import 'provider/data_of_clock_numbers.dart';

class AnalogClock extends StatefulWidget {
  const AnalogClock(this.model);

  final ClockModel model;

  @override
  _AnalogClockState createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock> with TickerProviderStateMixin {
  var _now = DateTime.now();
  var _temperature = '';
  var _temperatureRange = '';
  var _condition = '';
  var _location = '';
  double radiansPerTick = radians(180 / 59);
  double radiansPerMinutes = radians(360 / 10);
  double _radiansPerHour = radians(360 / 6);
  double _radians = radians(360 / 24);

  Timer _timer;
  GlobalKey _clockBoxKey = GlobalKey();
  Size _clockBoxSize = Size(0, 0);
  Offset _clockBoxPosition;
  _getSizes() {
    final RenderBox renderBoxRed = _clockBoxKey.currentContext.findRenderObject();
    final sizeRed = renderBoxRed.size;
    setState(() => _clockBoxSize = sizeRed);
  }
  _getPositions() {
    final RenderBox renderBoxRed = _clockBoxKey.currentContext.findRenderObject();
    final positionRed = renderBoxRed.localToGlobal(Offset.zero);
    setState(() => _clockBoxPosition = positionRed);
  }
  _afterLayout(_) {
    _getSizes();
    _getPositions();
  }

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    _updateTime();
    _updateModel();

    WidgetsBinding.instance.addPostFrameCallback(_afterLayout);
  }

  @override
  void didUpdateWidget(AnalogClock oldWidget) {
    super.didUpdateWidget(oldWidget);

    _clockBoxSize = MediaQuery.of(context).size;

    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      _temperature = widget.model.temperatureString;
      _temperatureRange = '(${widget.model.low} - ${widget.model.highString})';
      _condition = widget.model.weatherString;
      _location = widget.model.location;
      _radiansPerHour = radians(360 / (widget.model.is24HourFormat ? 10 : 12));
    });
  }

  void _updateTime() {
    setState(() {
      _now = DateTime.now();
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _now.millisecond),
        _updateTime,
      );
    });

    WidgetsBinding.instance.addPostFrameCallback(_afterLayout);
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.Hms().format(DateTime.now());
    final weatherInfo = DefaultTextStyle(
      style: TextStyle(color: Colors.red),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_temperature),
          Text(_temperatureRange),
          Text(_condition),
          Text(_location),
        ],
      ),
    );

    double clockSize = _clockBoxSize.height / 100 * 50;

    List<Widget> getListOfClockNumbers() {
      int activeNumberIndex = 0;

      List<Widget> _listOfNumbers = [];
      for (var index = 0; index < (widget.model.is24HourFormat ? 24 : 12); index++) {
        if (index == _now.hour) activeNumberIndex = index;
        ClockEffect clockEffect = ClockEffect(
          endRange: widget.model.is24HourFormat ? 24 : 12,
          index: index,
          gradualUpTo: 6,
          activeNumber: widget.model.is24HourFormat ? _now.hour : _now.hour > 12 ? _now.hour - 12 : _now.hour,
        );
        _listOfNumbers.add(Transform.rotate(
          angle: index * _radiansPerHour,
          origin: Offset(-(clockSize * 2 / 4), 0),
          alignment: FractionalOffset.center,
          child: Container(
            width: clockSize * 2 / 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Transform(
                transform: new Matrix4.translationValues(300, 0, 0)
                  ..setEntry(2, 1, 0.003)
                  ..rotateY(_radians * 90)
                  ..translate(0, 0, 0),
                alignment: Alignment.center,
                child: Container(
                  width: 1500,
                  height: 350,
                  child: Text(
                    (index < 10 ? "0" + index.toString() : index.toString()),
                    style: TextStyle(
                      fontSize: clockEffect.gradual(max: 250, min: 250),
                      color: Color.fromRGBO(
                        clockEffect.gradual(max: 255, min: 40).round(),
                        clockEffect.gradual(max: 44, min: 255).round(),
                        clockEffect.gradual(max: 91, min: 255).round(),
                        clockEffect.gradual(max: 1, min: 0),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
      }

      List<Widget> List_1 = _listOfNumbers.sublist(activeNumberIndex);
      List<Widget> List_2 = _listOfNumbers.sublist(0, activeNumberIndex);

      _listOfNumbers.clear();
      _listOfNumbers.addAll(List_2);
      _listOfNumbers.addAll(List_1.reversed);

      return _listOfNumbers;
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DataOfClockNumbers>(
          create: (_) => DataOfClockNumbers(),
        ),
      ],
      child: Semantics.fromProperties(
        key: _clockBoxKey,
        properties: SemanticsProperties(
          label: 'Analog clock with time $time',
          value: time,
        ),
        child: Stack(
          children: <Widget>[
            Container(
              width: _clockBoxSize.width,
              height: _clockBoxSize.height,
              color: Colors.white,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: weatherInfo,
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Transform(
                      transform: new Matrix4.rotationY(-(_radians * 90))
                        ..scale(0.5, 0.5)
                        ..rotateZ(-(_radiansPerHour * _now.hour)),
                      alignment: Alignment.center,
                      child: Stack(
                        children: <Widget>[
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: clockSize * 2,
                              height: clockSize * 2,
                              //color: Colors.black12,
                              child: Stack(
                                alignment: Alignment.centerRight,
                                children: getListOfClockNumbers(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ClockEffect {
  final int endRange;
  final int index;
  final int activeNumber;
  int gradualUpTo;

  ClockEffect({Key key, this.endRange, this.index, this.activeNumber, this.gradualUpTo = 0});

  double gradual({
    double max,
    double min,
  }) {
    assert(endRange != null && index != null && activeNumber != null && gradualUpTo != null && max != null && min != null);

    if (gradualUpTo >= endRange / 2) gradualUpTo = endRange ~/ 2;
    double _gradual = 0.0;

    if (index == activeNumber) {
      _gradual = max;
    } else if ((activeNumber - gradualUpTo >= 0 && index >= activeNumber - gradualUpTo && index < activeNumber) ||
        (activeNumber - gradualUpTo < 0 && (index >= (activeNumber - gradualUpTo) + endRange || index < activeNumber))) {
      if (activeNumber - gradualUpTo >= 0 && index >= activeNumber - gradualUpTo && index < activeNumber) {
        if (index == activeNumber - gradualUpTo) {
          _gradual = min;
        } else {
          _gradual = min + ((max - min) / gradualUpTo * ((index - (activeNumber - gradualUpTo)) - 1));
        }
      } else {
        if (index == (activeNumber - gradualUpTo) + endRange) {
          _gradual = min;
        } else {
          if (index > (activeNumber - gradualUpTo) + endRange) {
            _gradual = min + ((max - min) / gradualUpTo * ((index - ((activeNumber - gradualUpTo) + endRange)) - 1));
          } else {
            _gradual = min + ((max - min) / gradualUpTo * (((activeNumber - gradualUpTo).abs() + index) - 1));
          }
        }
      }
    } else if ((activeNumber + gradualUpTo <= endRange && index <= activeNumber + gradualUpTo && index > activeNumber) ||
        (activeNumber + gradualUpTo > endRange && (index <= ((activeNumber + gradualUpTo) - endRange) || index > activeNumber))) {
      if ((activeNumber + gradualUpTo <= endRange && index <= activeNumber + gradualUpTo && index > activeNumber)) {
        if (index == activeNumber + gradualUpTo) {
          _gradual = min;
        } else {
          _gradual = min + ((max - min) / gradualUpTo * (((activeNumber + gradualUpTo) - index) - 1));
        }
      } else {
        if (index == (activeNumber + gradualUpTo) - endRange) {
          _gradual = min;
        } else if (index <= endRange && index > activeNumber) {
          _gradual = min + ((max - min) / gradualUpTo * (((activeNumber + gradualUpTo) - index) - 1));
        } else {
          _gradual = min + ((max - min) / gradualUpTo * ((((activeNumber + gradualUpTo) - index) - 1) - endRange));
        }
      }
    }

    return _gradual;
  }
}
