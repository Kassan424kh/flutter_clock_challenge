import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import 'package:vector_math/vector_math_64.dart' show radians;

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
  double radiansPerSeconds = radians(360 / 10);
  double radiansPerMinutes = radians(360 / 10);
  double radiansPerHour = radians(360 / 12);
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

    return Semantics.fromProperties(
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
            color: Colors.black87,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: weatherInfo,
                  ),
                ),
                // Seconds
                ClockNumbers(
                  clockBoxSize: clockSize,
                  activeNumber: _now.second,
                  model: widget.model,
                  numbersLength: 60,
                  radians: _radians,
                  numberRadians: radiansPerSeconds,
                  activeNumberColor: Colors.tealAccent,
                  inactiveNumberColor: Colors.white70,
                  activeNumberOpacity: 1,
                  inactiveNumberOpacity: 0.4,
                  activeNumberSize: clockSize * 70 / 100,
                  inactiveNumberSize: clockSize * 35 / 100,
                  transitionX: (clockSize * 2) * 52.5 / 100,
                  transitionY: clockSize * 70 / 100,
                  scale: 0.3,
                  rotateDegree: 45,
                  positionedTop: (_clockBoxSize.height / 2 - clockSize),
                  positionedLeft: (_clockBoxSize.width / 2 - clockSize) + (clockSize * 58 / 100),
                ),

                // Minutes
                ClockNumbers(
                  clockBoxSize: clockSize,
                  activeNumber: _now.minute,
                  model: widget.model,
                  numbersLength: 60,
                  radians: _radians,
                  numberRadians: radiansPerMinutes,
                  activeNumberColor: Colors.pinkAccent,
                  inactiveNumberColor: Colors.white70,
                  activeNumberOpacity: 1,
                  inactiveNumberOpacity: 0.4,
                  activeNumberSize: clockSize * 78.5 / 100,
                  inactiveNumberSize: clockSize * 43.5 / 100,
                  transitionX: (clockSize * 2) * 52.5 / 100,
                  transitionY: clockSize * 70 / 100,
                  scale: 0.4,
                  rotateDegree: 45,
                  positionedTop: (_clockBoxSize.height / 2 - clockSize),
                  positionedLeft: (_clockBoxSize.width / 2 - clockSize),
                ),

                // Hours
                ClockNumbers(
                  clockBoxSize: clockSize,
                  activeNumber: widget.model.is24HourFormat ? _now.hour : _now.hour > 12 ? _now.hour - 12 : _now.hour,
                  model: widget.model,
                  numbersLength: widget.model.is24HourFormat ? 24 : 12,
                  radians: _radians,
                  numberRadians: radiansPerHour,
                  activeNumberColor: Colors.deepPurpleAccent,
                  inactiveNumberColor: Colors.white70,
                  activeNumberOpacity: 1,
                  inactiveNumberOpacity: 0.4,
                  activeNumberSize: clockSize * 78.5 / 100,
                  inactiveNumberSize: clockSize * 43.5 / 100,
                  transitionX: (clockSize * 2) * 52.5 / 100,
                  transitionY: clockSize * 70 / 100,
                  scale: 0.5,
                  rotateDegree: 45,
                  positionedTop: (_clockBoxSize.height / 2 - clockSize),
                  positionedLeft: (_clockBoxSize.width / 2 - clockSize) - (clockSize * 70 / 100),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class ClockNumbers extends StatelessWidget {
  final ClockModel model;
  final int numbersLength;
  final double numberRadians;
  final double radians;
  final double clockBoxSize;
  final int activeNumber;
  final Color activeNumberColor, inactiveNumberColor;
  final double activeNumberSize, inactiveNumberSize;
  final double activeNumberOpacity, inactiveNumberOpacity;
  final double transitionX, transitionY;
  final double scale;
  final int rotateDegree;
  final double positionedTop, positionedRight, positionedBottom, positionedLeft;

  ClockNumbers({
    Key key,
    this.model,
    this.numbersLength,
    this.radians,
    this.numberRadians,
    this.clockBoxSize,
    this.activeNumber = 0,
    this.activeNumberColor = Colors.deepPurple,
    this.inactiveNumberColor = Colors.deepPurpleAccent,
    this.activeNumberSize,
    this.inactiveNumberSize,
    this.activeNumberOpacity = 1,
    this.inactiveNumberOpacity = 0,
    this.transitionX = 300,
    this.transitionY = 200,
    this.scale = 0.5,
    this.rotateDegree,
    this.positionedTop,
    this.positionedRight,
    this.positionedBottom,
    this.positionedLeft,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> getListOfClockNumbers() {
      int activeNumberIndex = 0;

      List<Widget> _listOfNumbers = [];
      for (var index = 0; index < numbersLength; index++) {
        if (index == activeNumber) activeNumberIndex = index;
        ClockEffect clockEffect = ClockEffect(
          endRange: numbersLength,
          index: index,
          gradualUpTo: 4,
          activeNumber: activeNumber,
        );
        _listOfNumbers.add(Transform.rotate(
          angle: index * numberRadians,
          origin: Offset(-(clockBoxSize * 2 / 4), 0),
          alignment: Alignment.center,
          child: Container(
            width: clockBoxSize,
            height: clockBoxSize * 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: Transform(
              alignment: Alignment.center,
              transform: new Matrix4.translationValues(transitionX, transitionY, 0)..rotateY(radians * rotateDegree),
              child: Text(
                (index < 10 ? "0" + index.toString() : index.toString()),

                style: TextStyle(
                  fontFamily: "Ubuntu",
                  fontWeight: FontWeight.w700,
                  shadows: [
                    BoxShadow(
                      color: index == activeNumber ? activeNumberColor.withOpacity(0.2) : Colors.black38,
                      blurRadius: 50,
                    )
                  ],
                  fontSize: clockEffect.gradual(max: activeNumberSize, min: inactiveNumberSize),
                  color: Color.fromRGBO(
                    clockEffect.gradual(max: activeNumberColor.red.toDouble(), min: inactiveNumberColor.red.toDouble()).round(),
                    clockEffect.gradual(max: activeNumberColor.green.toDouble(), min: inactiveNumberColor.green.toDouble()).round(),
                    clockEffect.gradual(max: activeNumberColor.blue.toDouble(), min: inactiveNumberColor.blue.toDouble()).round(),
                    clockEffect.gradual(max: activeNumberOpacity, min: inactiveNumberOpacity),
                  ),
                ),
              ),
            ),
          ),
        ));
      }
      return ClockEffect.sort3DNumbers(_listOfNumbers, activeNumberIndex);
    }

    return Positioned(
      top: positionedTop,
      right: positionedRight,
      bottom: positionedBottom,
      left: positionedLeft,
      child: Transform(
        transform: new Matrix4.rotationY(-(radians * rotateDegree))
          ..scale(scale, scale)
          ..rotateZ(-(numberRadians * activeNumber)),
        alignment: Alignment.center,
        child: Container(
          width: clockBoxSize * 2,
          height: clockBoxSize * 2,
          child: Stack(
            overflow: Overflow.visible,
            alignment: Alignment.centerRight,
            children: getListOfClockNumbers(),
          ),
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

  double gradual({double max, double min}) {
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

  static List<Widget> sort3DNumbers(listOfNumbers, activeNumberIndex) {
    Widget _activeNumber = listOfNumbers[activeNumberIndex];
    Widget _inactiveNumber;

    List<Widget> _list1 = [];
    List<Widget> _list2 = [];

    List<Widget> _sortedNumbersList = [];

    listOfNumbers.remove(activeNumberIndex);

    if (listOfNumbers.length.isOdd) {
      int _halfIndexOfNumberList = (listOfNumbers.length / 2).round();

      if (activeNumberIndex - _halfIndexOfNumberList >= 0) {
        _inactiveNumber = listOfNumbers[activeNumberIndex - _halfIndexOfNumberList];
        listOfNumbers.remove(activeNumberIndex - _halfIndexOfNumberList);

        _halfIndexOfNumberList--;

        _list1.addAll(listOfNumbers.sublist(activeNumberIndex - 1));
        _list1.addAll(listOfNumbers.sublist(0, activeNumberIndex - _halfIndexOfNumberList - 1));
        _list1.replaceRange(0, _list1.length, _list1.reversed);

        _list2.addAll(listOfNumbers.sublist(activeNumberIndex - _halfIndexOfNumberList - 1, activeNumberIndex - 1));
      } else {
        _inactiveNumber = listOfNumbers[activeNumberIndex + _halfIndexOfNumberList - 1];
        listOfNumbers.remove(activeNumberIndex + _halfIndexOfNumberList);

        _halfIndexOfNumberList--;

        _list1.addAll(listOfNumbers.sublist(activeNumberIndex + _halfIndexOfNumberList));
        _list1.addAll(listOfNumbers.sublist(0, activeNumberIndex));

        _list2.addAll(listOfNumbers.sublist(activeNumberIndex, activeNumberIndex + _halfIndexOfNumberList));
        _list2.replaceRange(0, _list2.length, _list2.reversed);
      }
    } else {
      int _halfIndexOfNumberList = (listOfNumbers.length / 2).toInt();
      if (activeNumberIndex - _halfIndexOfNumberList >= 0) {
        _list1.addAll(listOfNumbers.sublist(activeNumberIndex));
        _list1.addAll(listOfNumbers.sublist(0, activeNumberIndex - _halfIndexOfNumberList));
        _list1.replaceRange(0, _list1.length, _list1.reversed);

        _list2.addAll(listOfNumbers.sublist(activeNumberIndex - _halfIndexOfNumberList, activeNumberIndex));
      } else {
        _list1.addAll(listOfNumbers.sublist(activeNumberIndex + _halfIndexOfNumberList));
        _list1.addAll(listOfNumbers.sublist(0, activeNumberIndex));

        _list2.addAll(listOfNumbers.sublist(activeNumberIndex, activeNumberIndex + _halfIndexOfNumberList));
        _list2.replaceRange(0, _list2.length, _list2.reversed);
      }
    }

    if (_inactiveNumber != null) _sortedNumbersList.add(_inactiveNumber);

    for (var indexOfSplitedNumbers = 0; indexOfSplitedNumbers < _list1.length; indexOfSplitedNumbers++) {
      _sortedNumbersList.add(_list1[indexOfSplitedNumbers]);
      _sortedNumbersList.add(_list2[indexOfSplitedNumbers]);
    }

    _sortedNumbersList.add(_activeNumber);

    return _sortedNumbersList;
  }
}


