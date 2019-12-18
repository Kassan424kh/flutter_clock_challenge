import 'dart:async';

import 'package:flutter/cupertino.dart';
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

  AnimationController _animationControllerHours;
  AnimationController _animationControllerMinutes;
  Animation<double> _animationHours;
  Animation<double> _animationMinutes;

  double radiansPerTick = radians(360 / 10);
  double radiansPerHour = radians(360 / 24);

  Timer _timer;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    _updateTime();
    _updateModel();

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

    Size displaySize = MediaQuery.of(context).size;
    double clockSize = displaySize.width;
    double numbersSize = 100;

    List<Widget> listOfHourNumbers() {
      List<Widget> hourNumbers = [];
      for (var hour = 0; hour < (widget.model.is24HourFormat ? 24 : 12); hour++)
        hourNumbers.add(Align(
          alignment: Alignment.topCenter,
          child: Transform.rotate(
            alignment: Alignment.topCenter,
            angle: -(radiansPerHour * hour),
            origin: Offset(0, clockSize / 2),
            child: Container(
              width: numbersSize,
              height: clockSize / 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 10),
                  AnimatedOpacity(
                    opacity: hour == _now.hour ? 1 : 0.4,
                    duration: Duration(milliseconds: 350),
                    child: Text(
                      (hour == 0 ? 12 : hour).toString(),
                      style: TextStyle(
                        fontSize: hour == _now.hour ? numbersSize - numbersSize / 3 : numbersSize / 5,
                        fontFamily: "Righteous",
                        color: customTheme.primaryColor,
                        shadows: [
                          BoxShadow(
                            offset: Offset(0, 5),
                            color: numbersShadowColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: (numbersSize / 2) - (numbersSize / 2.5),
                  ),
                  AnimatedOpacity(
                    opacity: hour == _now.hour ? 1 : 0.4,
                    duration: Duration(milliseconds: 350),
                    child: Container(
                      width: (numbersSize / 2) - (numbersSize / 2.5),
                      height: (numbersSize / 2) - (numbersSize / 2.5),
                      decoration: BoxDecoration(
                        color: customTheme.primaryColor,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ));
      return hourNumbers;
    }

    List<Widget> listOfMinutesNumbers() {
      List<Widget> minuteNumbers = [];
      for (var minute = 0; minute < 60; minute++)
        minuteNumbers.add(
          (minute <= _now.minute + 5) && (minute >= _now.minute - 5) || (_now.minute < 5 && (minute < 5 || minute > 56) || _now.minute >= 55 && minute < 3)
              ? Align(
                  alignment: Alignment.topCenter,
                  child: Transform.rotate(
                    alignment: Alignment.topCenter,
                    angle: radiansPerTick * minute,
                    origin: Offset(0, (clockSize / 2) / 2),
                    child: Container(
                      width: numbersSize / 2,
                      height: (clockSize / 2) / 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(height: 10),
                          AnimatedOpacity(
                            opacity: minute == _now.minute ? 1 : 0.4,
                            duration: Duration(milliseconds: 350),
                            child: Container(
                              height: (numbersSize / 2) - (numbersSize / 2.5),
                              width: (numbersSize / 2) - (numbersSize / 2.5),
                              decoration: BoxDecoration(
                                color: customTheme.highlightColor,
                                borderRadius: BorderRadius.all(Radius.circular(20)),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: (numbersSize / 2) - (numbersSize / 2.5),
                          ),
                          AnimatedOpacity(
                            opacity: minute == _now.minute ? 1 : 0.4,
                            duration: Duration(milliseconds: 350),
                            child: Text(
                              (minute).toString(),
                              style: TextStyle(
                                fontSize: minute == _now.minute ? numbersSize / 2.1 : numbersSize / 4,
                                fontFamily: "Gruppo",
                                fontWeight: FontWeight.w700,
                                color: customTheme.highlightColor,
                                shadows: [
                                  BoxShadow(
                                    offset: Offset(0, 2),
                                    color: numbersShadowColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Container(),
        );

      return minuteNumbers;
    }

    return Semantics.fromProperties(
      properties: SemanticsProperties(
        label: 'Analog clock with time $time',
        value: time,
      ),
      child: Stack(
        children: <Widget>[
          Container(
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

                // hours Numbers
                Positioned(
                  left: displaySize.width / 2 - clockSize / 2,
                  top: displaySize.width / 9,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _animationControllerHours,
                      child: Container(
                        width: clockSize,
                        height: clockSize,
                        decoration: BoxDecoration(
                          color: customTheme.accentColor,
                          borderRadius: BorderRadius.all(
                            Radius.circular(clockSize),
                          ),
                        ),
                        child: Stack(children: listOfHourNumbers()),
                      ),
                      builder: (BuildContext context, Widget _widget) {
                        _now.hour;
                        return Transform.rotate(
                          alignment: Alignment.center,
                          angle: radiansPerHour * ((_animationHours.value + double.parse((_now.minute / 60 * 100).toStringAsFixed(0)) / 100)),
                          child: _widget,
                        );
                      },
                    ),
                  ),
                ),

                // minutes Numbers
                Positioned(
                    left: displaySize.width / 2 - clockSize / 4,
                    top: displaySize.width / 5.5 + clockSize / 6,
                    child: AnimatedBuilder(
                        animation: _animationControllerMinutes,
                        child: Container(
                          width: clockSize / 2,
                          height: clockSize / 2,
                          decoration: BoxDecoration(
                            //color: Colors.black12,
                            borderRadius: BorderRadius.all(
                              Radius.circular(clockSize),
                            ),
                          ),
                          child: Stack(children: listOfMinutesNumbers()),
                        ),
                        builder: (BuildContext context, Widget widget) {
                          _now.minute;
                          return Transform.rotate(
                            alignment: Alignment.center,
                            angle: -((radiansPerTick * _animationMinutes.value)),
                            child: widget,
                          );
                        })),

                // Clock Hand
                /*Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: (numbersSize / 2) - (numbersSize / 2.5),
                    height: displaySize.width,
                    child: Stack(children: <Widget>[
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          margin: EdgeInsets.only(top: 30),
                          width: (numbersSize / 2) - (numbersSize / 2.5),
                          height: 79,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            border: Border.all(
                              color: handColor,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),*/
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ClockNumbers extends StatelessWidget {
  final opacity;
  final is24HourFormat;
  final displaySize;
  final numbersSize;
  final nowType;
  final radians;
  final clockSize;
  final showQuestion;
  final animationController;
  final animation;
  final hourFormat;
  final isHour;
  final nowNumberSize;
  final notNowNumberSize;
  final numbersColor;
  final backgroundColor;
  final numbersShadow;
  final spaceBetweenNumberAndDot;
  final dotsSize;
  final isDirectionNumbersLeft;
  final positionLeft;
  final positionTop;

  ClockNumbers({
    Key key,
    this.opacity,
    this.is24HourFormat,
    this.displaySize,
    this.nowType,
    this.radians,
    this.clockSize,
    this.showQuestion,
    this.animationController,
    this.animation,
    this.hourFormat,
    this.isHour,
    this.nowNumberSize,
    this.notNowNumberSize,
    this.numbersColor,
    this.backgroundColor,
    this.numbersShadow,
    this.spaceBetweenNumberAndDot,
    this.dotsSize,
    this.numbersSize,
    this.isDirectionNumbersLeft,
    this.positionLeft,
    this.positionTop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> listOfNumbers() {
      List<Widget> minuteNumbers = [];
      for (var number = 0; number < isHour ? hourFormat : 60; number++)
        minuteNumbers.add(
          (showQuestion) || !isHour
              ? Align(
                  alignment: Alignment.topCenter,
                  child: Transform.rotate(
                    alignment: Alignment.topCenter,
                    angle: isHour ? -(radians * number) : (radians * number),
                    origin: Offset(0, clockSize / 2),
                    child: Container(
                      width: numbersSize,
                      height: clockSize,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(height: 10),
                          !isHour
                              ? AnimatedOpacity(
                                  opacity: number == nowType ? 1 : opacity,
                                  duration: Duration(milliseconds: 350),
                                  child: Container(
                                    height: dotsSize,
                                    width: dotsSize,
                                    decoration: BoxDecoration(
                                      color: numbersColor,
                                      borderRadius: BorderRadius.all(Radius.circular(20)),
                                    ),
                                  ),
                                )
                              : Container(),
                          SizedBox(
                            height: spaceBetweenNumberAndDot,
                          ),
                          AnimatedOpacity(
                            opacity: number == nowType ? 1 : opacity,
                            duration: Duration(milliseconds: 350),
                            child: Text(
                              (number).toString(),
                              style: TextStyle(
                                fontSize: number == nowType ? nowNumberSize : notNowNumberSize,
                                fontFamily: "Gruppo",
                                fontWeight: FontWeight.w700,
                                color: numbersColor,
                                shadows: [
                                  numbersShadow,
                                ],
                              ),
                            ),
                          ),
                          isHour
                              ? AnimatedOpacity(
                                  opacity: number == nowType ? 1 : opacity,
                                  duration: Duration(milliseconds: 350),
                                  child: Container(
                                    height: dotsSize,
                                    width: dotsSize,
                                    decoration: BoxDecoration(
                                      color: numbersColor,
                                      borderRadius: BorderRadius.all(Radius.circular(20)),
                                    ),
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  ),
                )
              : Container(),
        );

      return minuteNumbers;
    }

    return Positioned(
      left: positionLeft,
      top: positionTop,
      child: AnimatedBuilder(
        animation: animationController,
        child: Container(
          width: clockSize,
          height: clockSize,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.all(
              Radius.circular(clockSize),
            ),
          ),
          child: Stack(children: listOfNumbers()),
        ),
        builder: (BuildContext context, Widget widget) {
          nowType;
          return Transform.rotate(
            alignment: Alignment.center,
            angle: isDirectionNumbersLeft ? -((radians * animation.value)) : -((radians * animation.value)),
            child: widget,
          );
        },
      ),
    );
  }
}

class ClockHand extends StatelessWidget {
  final handWidth;
  final handHeight;
  final dotSize;
  final handColor;

  ClockHand({
    Key key,
    this.handWidth,
    this.handHeight,
    this.dotSize,
    this.handColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: dotSize,
        height: handHeight,
        child: Stack(children: <Widget>[
          Align(
            alignment: Alignment.center,
            child: Container(
              margin: EdgeInsets.only(top: 30),
              width: dotSize,
              height: handHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                border: Border.all(
                  color: handColor,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
