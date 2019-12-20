import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
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

  double radiansPerTick = radians(360 / 10);
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
            primaryColor: Color(0xFFFE4A49),
            highlightColor: Color(0xFF2176FF),
            accentColor: Colors.white,
            backgroundColor: Color(0xffFBF5F3),
          )
        : Theme.of(context).copyWith(
            primaryColor: Color(0xFF4285F4),
            highlightColor: Color(0xFF31dd82),
            accentColor: Colors.black12,
            backgroundColor: Color(0xff072f43),
          );
    final handColor = Theme.of(context).brightness == Brightness.light ? Color(0xffEFDDD7) : Colors.white30;
    final numbersShadowColor = Theme.of(context).brightness == Brightness.light ? Color(0xffEFDDD7) : Color(0xff072433);

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

    double clockSize = _clockBoxSize.width;
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

                  // hours
                  ClockNumbers(
                    opacity: 0.4,
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
                    notNowNumberSize: numbersSize / 5,
                    numbersColor: customTheme.primaryColor,
                    backgroundColor: customTheme.accentColor,
                    numberShadows: [
                      BoxShadow(
                        offset: Offset(0, 5),
                        color: numbersShadowColor,
                      ),
                    ],
                    spaceBetweenNumberAndDot: (numbersSize / 2) - (numbersSize / 2.5),
                    dotsSize: (numbersSize / 2) - (numbersSize / 2.5),
                    isDirectionNumbersLeft: true,
                    positionLeft: _clockBoxSize.width / 2 - clockSize / 2,
                    positionTop: _clockBoxSize.width / 9,
                  ),

                  // minutes
                  ClockNumbers(
                    opacity: 0.4,
                    is24HourFormat: true,
                    displaySize: _clockBoxSize,
                    numbersSize: numbersSize,
                    nowType: _now.minute,
                    radians: radiansPerTick,
                    clockSize: clockSize / 2,
                    animationController: _animationControllerMinutes,
                    animation: _animationMinutes,
                    isHour: false,
                    nowNumberSize: numbersSize / 2.1,
                    notNowNumberSize: numbersSize / 4,
                    numbersColor: customTheme.highlightColor,
                    backgroundColor: Colors.transparent,
                    numberShadows: [
                      BoxShadow(
                        offset: Offset(0, 5),
                        color: numbersShadowColor,
                      ),
                    ],
                    spaceBetweenNumberAndDot: (numbersSize / 2) - (numbersSize / 2.5),
                    dotsSize: (numbersSize / 2) - (numbersSize / 2.5),
                    isDirectionNumbersLeft: false,
                    positionLeft: _clockBoxSize.width / 2 - clockSize / 4,
                    positionTop: _clockBoxSize.width / 5.5 + clockSize / 6,
                  ),

                  // Clock Hand
                  ClockHand(
                      handWidth: (numbersSize / 2) - (numbersSize / 2.5),
                      handHeight: _clockBoxSize.height / 5.685,
                      positionLeft: _clockBoxSize.width / 2 - clockSize / 2,
                      positionTop: _clockBoxSize.width / 9,
                      dotSize: (numbersSize / 2) - (numbersSize / 2.5),
                      clockBoxSize: _clockBoxSize,
                      handColor: handColor,
                      clockBoxPosition: _clockBoxPosition),
                  /*Align(
                    alignment: Alignment.center,
                    child: CustomPaint(
                      painter: new X1Painter(),
                    ),
                  ),*/
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class X1Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // create a bounding square, based on the centre and radius of the arc
    Rect rect = new Rect.fromCircle(
      center: new Offset(0.0, 0.0),
      radius: 180.0,
    );

    // a fancy rainbow gradient
    final Gradient gradient = LinearGradient(
      colors: <Color>[
        Color(0xFFF80051),
        Color(0xFFFBBCBA),
        Color(0xffFBF5F3)
      ],
      stops: [
        0.0,
        0.05,
        1.0
      ],
    );

    // create the Shader from the gradient and the bounding square
    final Paint paint = new Paint()..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke;

    // and draw an arc
    canvas.drawArc(rect, pi, pi * 2, true, paint);


  }

  @override
  bool shouldRepaint(X1Painter oldDelegate) {
    return true;
  }
}
