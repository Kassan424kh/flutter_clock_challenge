import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import 'package:vector_math/vector_math_64.dart' show radians;
import 'package:provider/provider.dart';

import 'clock_hand.dart';
import 'clock_numbers.dart';
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

  AnimationController _animationControllerHours;
  AnimationController _animationControllerMinutes;
  Animation<double> _animationHours;
  Animation<double> _animationMinutes;

  double radiansPerTick = radians(180 / 59);
  double radiansPerMinutes = radians(360 / 10);
  double radiansPerHour = radians(360 / 24);

  GlobalKey _clockBoxKey = GlobalKey();
  Size _clockBoxSize = Size(0, 0);
  Offset _clockBoxPosition;

  Timer _timer;

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

    _animationControllerHours = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    );

    _animationControllerMinutes = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    );

    _animationHours = Tween<double>(begin: _now.hour.toDouble(), end: _now.hour.toDouble()).animate(
      CurvedAnimation(
        parent: _animationControllerHours,
        curve: Curves.easeInOutQuart,
      ),
    );

    _animationMinutes = Tween<double>(begin: _now.minute.toDouble(), end: _now.minute.toDouble()).animate(
      CurvedAnimation(
        parent: _animationControllerMinutes,
        curve: Curves.easeInOutQuart,
      ),
    );

    _animationControllerHours.forward();
  }

  @override
  void didUpdateWidget(AnalogClock oldWidget) {
    super.didUpdateWidget(oldWidget);

    _clockBoxSize = MediaQuery.of(context).size;

    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
      radiansPerHour = radians(360 / (oldWidget.model.is24HourFormat ? 24 : 12));
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
    if (_now.hour != DateTime.now().hour && _animationControllerHours != null) {
      setState(() {
        _animationHours = Tween(begin: DateTime.now().hour - 0.0001, end: DateTime.now().hour.toDouble()).animate(
          CurvedAnimation(
            parent: _animationControllerHours,
            curve: Curves.easeInOutQuart,
          ),
        );

        _animationControllerHours.duration = Duration(milliseconds: 350);
        _animationControllerHours.forward(from: 0);
      });
    } else if (_now.minute != DateTime.now().minute && _animationControllerHours != null) {
      setState(() {
        _animationMinutes = Tween(begin: DateTime.now().minute - 1.0001, end: DateTime.now().minute.toDouble()).animate(
          CurvedAnimation(
            parent: _animationControllerMinutes,
            curve: Curves.easeInOutQuart,
          ),
        );

        _animationControllerMinutes.duration = Duration(milliseconds: 350);
        _animationControllerMinutes.forward(from: 0);
      });
    }

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
    final customTheme = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).copyWith(
            primaryColor: Color(0xFF0027D8),
            highlightColor: Color(0xffFF4365),
            accentColor: Color(0xffFFFFF3),
            backgroundColor: Color(0xff2541B2),
          )
        : Theme.of(context).copyWith(
            primaryColor: Color(0xFF4285F4),
            highlightColor: Color(0xFF31dd82),
            accentColor: Colors.black12,
            backgroundColor: Color(0xff072f43),
          );
    final handColor = Theme.of(context).brightness == Brightness.light ? Colors.black26 : Colors.white30;

    final time = DateFormat.Hms().format(DateTime.now());
    final weatherInfo = DefaultTextStyle(
      style: TextStyle(color: customTheme.primaryColor),
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

    double clockSize = _clockBoxSize.width * 90 / 100;
    double numbersSize = clockSize / 6;

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
              color: customTheme.backgroundColor,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: weatherInfo,
                    ),
                  ),

                  Positioned(
                    left: _clockBoxSize.width / 2 - _clockBoxSize.width / 2,
                    top: _clockBoxSize.width / 8 - (_clockBoxSize.width / 2 - clockSize / 2),
                    child: Container(
                      width: _clockBoxSize.width,
                      height: _clockBoxSize.width,
                      decoration: BoxDecoration(
                        color: Color(0xff2541B2),
                        borderRadius: BorderRadius.all(
                          Radius.circular(_clockBoxSize.width),
                        ),
                      ),
                      child: Stack(
                        children: <Widget>[
                          for (var second = 0; second < 60; second++)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Transform.rotate(
                                alignment: Alignment.topCenter,
                                angle: second * radiansPerTick,
                                origin: Offset(_clockBoxSize.width / 4, (_clockBoxSize.width / 700) / 2),
                                child: Container(
                                  width: _clockBoxSize.width / 2,
                                  height: _clockBoxSize.width / 700,
                                  child: Stack(children: <Widget>[
                                    Align(
                                      alignment: Alignment.centerLeft.add(Alignment(0.05, 0)),
                                      child: Container(
                                        width: [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55].contains(second) ? (_clockBoxSize.width / 50) : (_clockBoxSize.width / 100),
                                        height: _clockBoxSize.width / 700,
                                        color: second == _now.second
                                            ? Color(0xffffffff)
                                            : second == (_now.second - 1)
                                                ? Color(0xff49CFE9)
                                                : second == (_now.second - 2) ? Color(0xff1CC3E3) : second == (_now.second - 3) ? Color(0xff047990) : Color(0xff03256C),
                                      ),
                                    )
                                  ]),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // hours
                  ClockNumbers(
                    is24HourFormat: true,
                    displaySize: _clockBoxSize,
                    numbersSize: numbersSize,
                    nowType: _now.hour,
                    radians: radiansPerHour,
                    clockSize: clockSize,
                    animationController: _animationControllerHours,
                    animation: _animationHours,
                    isHour: true,
                    nowNumberSize: numbersSize / 1.3,
                    notNowNumberSize: numbersSize / 3.5,
                    nowNumberColor: customTheme.primaryColor,
                    notNowNumberColor: Color(0xffB7AD99),
                    backgroundColor: customTheme.accentColor,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xff03256C),
                        blurRadius: 50,
                        offset: Offset(0, -15),
                      ),
                    ],
                    spaceBetweenNumberAndDot: (numbersSize / 2) - (numbersSize / 2.5),
                    dotsSize: (numbersSize / 2) - (numbersSize / 2.5),
                    isDirectionNumbersLeft: true,
                    positionLeft: _clockBoxSize.width / 2 - clockSize / 2,
                    positionTop: _clockBoxSize.width / 8,
                  ),

                  // minutes
                  ClockNumbers(
                    is24HourFormat: true,
                    displaySize: _clockBoxSize,
                    numbersSize: numbersSize,
                    nowType: _now.minute,
                    radians: radiansPerMinutes,
                    clockSize: clockSize / 2,
                    animationController: _animationControllerMinutes,
                    animation: _animationMinutes,
                    isHour: false,
                    nowNumberSize: numbersSize / 2.1,
                    notNowNumberSize: numbersSize / 4,
                    nowNumberColor: customTheme.highlightColor,
                    notNowNumberColor: Color(0xffB7AD99),
                    spaceBetweenNumberAndDot: (numbersSize / 2) - (numbersSize / 2.5),
                    dotsSize: (numbersSize / 2) - (numbersSize / 2.5),
                    isDirectionNumbersLeft: false,
                    positionLeft: _clockBoxSize.width / 2 - clockSize / 4,
                    positionTop: _clockBoxSize.width / 3.03,
                  ),

                  // Clock Hand
                  ClockHand(
                    handWidth: (numbersSize / 4.5),
                    handHeight: _clockBoxSize.height / 6.785,
                    positionTop: _clockBoxSize.width / 9,
                    dotSize: (numbersSize / 2) - (numbersSize / 2.5),
                    clockBoxSize: _clockBoxSize,
                    handColor: handColor,
                    clockBoxPosition: _clockBoxPosition,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class DolDurmaClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = new Path()..lineTo(0.0, size.height / 2)..lineTo(size.width, size.height / 2)..lineTo(size.width, 0);
    return path;
  }

  @override
  bool shouldReclip(DolDurmaClipper oldClipper) => true;
}
