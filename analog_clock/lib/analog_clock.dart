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
  double _radiansPerHour = radians(360 / 10);
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
                ClockNumbers(
                  clockBoxSize: clockSize,
                  activeNumber: widget.model.is24HourFormat ? _now.hour : _now.hour > 12 ? _now.hour - 12 : _now.hour,
                  model: widget.model,
                  numberLengths: widget.model.is24HourFormat ? 24 : 12,
                  radians: _radians,
                  numberRadians: _radiansPerHour,
                )
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
  final int numberLengths;
  final double numberRadians;
  final double radians;
  final double clockBoxSize;
  final int activeNumber;

  ClockNumbers({
    Key key,
    this.model,
    this.numberLengths,
    this.radians,
    this.numberRadians,
    this.clockBoxSize,
    this.activeNumber,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> getListOfClockNumbers() {
      int activeNumberIndex = 0;

      List<Widget> _listOfNumbers = [];
      for (var index = 0; index < numberLengths; index++) {
        if (index == activeNumber) activeNumberIndex = index;
        ClockEffect clockEffect = ClockEffect(
          endRange: numberLengths,
          index: index,
          gradualUpTo: 4,
          activeNumber: activeNumber,
        );
        _listOfNumbers.add(Transform.rotate(
          angle: index * numberRadians,
          origin: Offset(-(clockBoxSize * 2 / 4), 0),
          alignment: FractionalOffset.center,
          child: Container(
            width: clockBoxSize * 2 / 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Transform(
                transform: new Matrix4.translationValues(250, 0, 0)..rotateY(radians * 90),
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.all(Radius.circular(10))),
                  child: Text(
                    (index < 10 ? "0" + index.toString() : index.toString()),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      shadows: [
                        BoxShadow(
                          color: index == activeNumber ? Color.fromRGBO(247, 23, 53, 0.1) : Colors.transparent,
                          blurRadius: 30,
                        )
                      ],
                      fontSize: clockEffect.gradual(max: 250, min: 100),
                      color: Color.fromRGBO(
                        clockEffect.gradual(max: 247, min: 8).round(),
                        clockEffect.gradual(max: 23, min: 26).round(),
                        clockEffect.gradual(max: 53, min: 51).round(),
                        clockEffect.gradual(max: 1, min: 0.1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
      }
      return ClockEffect.sort3DNumbers(_listOfNumbers, activeNumberIndex);
    }

    return Align(
      alignment: Alignment.center,
      child: Transform(
        transform: new Matrix4.rotationY(-(radians * 90))
          ..scale(0.5, 0.5)
          ..rotateZ(-(numberRadians * activeNumber)),
        alignment: Alignment.center,
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.center,
              child: Container(
                width: clockBoxSize * 2,
                height: clockBoxSize * 2,
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
