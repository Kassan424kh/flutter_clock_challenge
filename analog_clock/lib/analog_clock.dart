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
            primaryColor: Color(0xFFE82F5D),
            highlightColor: Color(0xff26A195),
            accentColor: Color(0xffE7E9EB),
            backgroundColor: Color(0xffE7E9EB),
          )
        : Theme.of(context).copyWith(
            primaryColor: Color(0xFFFF3366),
            highlightColor: Color(0xff2EC4B6),
            accentColor: Color(0xff011627),
            backgroundColor: Color(0xff011627),
          );
    Color handColor = Theme.of(context).brightness == Brightness.light ? Colors.black26 : Colors.white30;
    Color _notNowNumbersColor = Theme.of(context).brightness == Brightness.light ? Color(0xffD0D4D7) : Color(0xff747F89);

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
    double numbersSize = clockSize / 5;
    Offset _offset = Offset(0.4, 0.7);

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
                  Align(
                    alignment: Alignment.center,
                    child: Transform(
                      transform: new Matrix4.rotationY(-(radiansPerHour * 90)),
                      alignment: Alignment.center,
                      child: Container(
                        width: _clockBoxSize.height,
                        height: _clockBoxSize.height,
                        color: Colors.black12,
                        child: Stack(alignment: Alignment.centerRight, children: <Widget>[
                          for (var i = 0; i < 24; i++)
                            Transform.rotate(
                              angle: i * radiansPerHour,
                              origin: Offset(-(_clockBoxSize.height / 2 / 2), 0),
                              alignment: FractionalOffset.center,
                              child: Container(
                                width: _clockBoxSize.height / 2,
                                height: 50,
                                color: Colors.white30,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Transform(
                                    transform: new Matrix4.rotationY(radiansPerHour * 90),
                                    alignment: Alignment.center,
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      constraints: BoxConstraints(minWidth: 50, maxWidth: 50),
                                      color: Colors.black12,
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                          i.toString(),
                                          style: TextStyle(fontSize: 30, color: Colors.redAccent)
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                        ]),
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
