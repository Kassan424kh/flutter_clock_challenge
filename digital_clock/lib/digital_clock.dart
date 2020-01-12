import 'dart:ui';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';

enum _Element {
  primary,
  hour,
  minute,
  centerShadow,
}

final _lightTheme = {
  _Element.primary: Colors.white,
  _Element.hour: [
    Color(0xff002fff),
    Color(0xff00f4ff),
  ],
  _Element.minute: [
    Color(0xff4B00FF),
    Color(0xffff00d9),
  ],
  _Element.centerShadow: Color(0xff6F0FFF),
};
final _darkTheme = {
  _Element.primary: Color(0xff0a0060),
  _Element.hour: [
    Color(0xff002fff),
    Color(0xff00f4ff),
  ],
  _Element.minute: [
    Color(0xff4B00FF),
    Color(0xffff00d9),
  ],
  _Element.centerShadow: Color(0xff6F0FFF),
};

class DigitalClock extends StatefulWidget {
  const DigitalClock(this.model);

  final ClockModel model;

  @override
  _DigitalClockState createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock> with TickerProviderStateMixin {
  var _now = DateTime.now();
  var _temperature = '';
  var _temperatureRange = '';
  var _condition = '';
  var _location = '';

  DateTime _oldTime;

  Timer _timer;
  GlobalKey _clockBoxKey = GlobalKey();
  Size _clockBoxSize = Size(0, 0);

  AnimationController _animationControllerShadowEffect, _animationControllerHour, _animationControllerMinute;
  Animation<double> _shadowAnimation, _hourAnimation, _minuteAnimation;

  _getSizes(_) {
    final RenderBox renderBoxRed = _clockBoxKey.currentContext.findRenderObject();
    final sizeRed = renderBoxRed.size;
    setState(() => _clockBoxSize = sizeRed);
  }

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    _updateTime();
    _updateModel();

    _animationControllerShadowEffect = AnimationController(vsync: this, duration: Duration(seconds: 1));
    _animationControllerHour = AnimationController(vsync: this, duration: Duration(seconds: 1));
    _animationControllerMinute = AnimationController(vsync: this, duration: Duration(seconds: 1));

    _shadowAnimation = Tween(begin: 0.0, end: 100.0).animate(CurvedAnimation(parent: _animationControllerShadowEffect, curve: Curves.easeInOutCubic))..addListener(() => setState(() {}));
    _hourAnimation = Tween(begin: 0.0, end: 100.0).animate(CurvedAnimation(parent: _animationControllerHour, curve: Curves.easeInOutCubic))..addListener(() => setState(() {}));
    _minuteAnimation = Tween(begin: 0.0, end: 100.0).animate(CurvedAnimation(parent: _animationControllerMinute, curve: Curves.easeInOutCubic))..addListener(() => setState(() {}));

    _animationControllerShadowEffect.forward().whenCompleteOrCancel(() {
      Timer(Duration(milliseconds: 300), () {
        _animationControllerHour.forward().whenCompleteOrCancel(() {
          _animationControllerMinute.forward();
        });
      });
    });

    WidgetsBinding.instance.addPostFrameCallback(_getSizes);
  }

  @override
  void didUpdateWidget(DigitalClock oldWidget) {
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
    // update Hour Animation
    if (_animationControllerHour != null && _animationControllerHour.isCompleted && _animationControllerShadowEffect.isCompleted && _now.minute == 59 && _now.second == 58) {
      _animationControllerHour.reverse().whenCompleteOrCancel(() {
        _animationControllerHour.forward(from: 0);
      });
    }

    // update Minute Animation
    if (_animationControllerMinute != null && _animationControllerMinute.isCompleted && _animationControllerShadowEffect.isCompleted && _now.second == 58) {
      _animationControllerMinute.reverse().whenCompleteOrCancel(() {
        _animationControllerMinute.forward(from: 0);
      });
    }

    setState(() {
      _now = DateTime.now();
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _now.millisecond),
        _updateTime,
      );
    });

    WidgetsBinding.instance.addPostFrameCallback(_getSizes);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).brightness == Brightness.light ? _lightTheme : _darkTheme;
    final time = DateFormat.Hms().format(DateTime.now());
    /*final weatherInfo = DefaultTextStyle(
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
    );*/

    double clockSize = _clockBoxSize.height / 2;

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
            color: colors[_Element.primary],
            child: Stack(
              children: [
                ClockNumbers(
                  fontSize: clockSize * 1.4,
                  clockNumber: _now.minute,
                  clockBoxSize: clockSize,
                  positionTop: clockSize / 2.8,
                  positionLeft: clockSize * 120 / 100,
                  number3dEffectSize: clockSize * 0.25 / 100,
                  firstNumberColor: colors[_Element.primary],
                  gradientColors: colors[_Element.minute],
                  animation: _minuteAnimation,
                ),
                CenterShadowEffect(
                  trueClockBoxSize: _clockBoxSize,
                  clockSize: clockSize,
                  shadowAnimation: _shadowAnimation,
                  backgroundColor: colors[_Element.primary],
                  shadowColor: (colors[_Element.centerShadow] as Color).withOpacity(0.3),
                ),
                ClockNumbers(
                  fontSize: clockSize * 1.4,
                  clockNumber: _now.hour,
                  clockBoxSize: clockSize,
                  positionTop: -(clockSize * 20 / 100),
                  positionLeft: clockSize * 4 / 100,
                  number3dEffectSize: clockSize * 0.25 / 100,
                  firstNumberColor: colors[_Element.primary],
                  gradientColors: colors[_Element.hour],
                  animation: _hourAnimation,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class ClockNumbers extends StatefulWidget {
  final int clockNumber;
  final double clockBoxSize;
  final double positionTop, positionLeft;
  final double fontSize;
  final double number3dEffectSize;
  final Color firstNumberColor;
  final List<Color> gradientColors;
  final bool isTypeHour;
  final Animation animation;

  ClockNumbers({
    Key key,
    this.fontSize,
    this.clockNumber = 0,
    this.clockBoxSize,
    this.positionTop = 0,
    this.positionLeft = 0,
    this.number3dEffectSize = 0.5,
    this.gradientColors,
    this.firstNumberColor,
    this.isTypeHour,
    this.animation,
  }) : super(key: key);

  @override
  _ClockNumbersState createState() => _ClockNumbersState();
}

class _ClockNumbersState extends State<ClockNumbers> {
  GlobalKey _numberGKey = GlobalKey();
  RenderBox _numberRenderBox;
  List<Widget> _number3DEffect = [];
  Shader _shader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.transparent, Colors.transparent],
    stops: [0.0, 1.0],
    tileMode: TileMode.clamp,
  ).createShader(
    Rect.fromCircle(
      center: Offset(0, 0),
      radius: 300,
    ),
  );

  Shader linearGradient(RenderBox renderBox) {
    if (renderBox == null) return null;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: widget.gradientColors.map((color) {
        return color.withOpacity(widget.animation.value / 100);
      }).toList(),
      stops: [0.0, 1.0],
      tileMode: TileMode.clamp,
    ).createShader(
      Rect.fromCircle(
        center: Offset(
          renderBox.localToGlobal(Offset.zero).dx + renderBox.size.width,
          renderBox.localToGlobal(Offset.zero).dy,
        ),
        radius: 100,
      ),
    );
  }

  _listOf3DNumbers() {
    _number3DEffect.clear();
    for (var number = 0; number < 40; number++)
      _number3DEffect.add(Align(
        alignment: Alignment.topCenter,
        child: Stack(
          children: <Widget>[
            Container(),
            Positioned(
              top: (widget.number3dEffectSize * number).toDouble(),
              left: (widget.number3dEffectSize * number).toDouble(),
              child: Text(
                (widget.clockNumber < 10 ? "0${widget.clockNumber}" : widget.clockNumber).toString(),
                key: number == 0 ? _numberGKey : null,
                style: TextStyle(
                  fontFamily: "ubuntu",
                  fontSize: widget.fontSize,
                  foreground: number != 0 ? (Paint()..shader = _shader) : null,
                  color: number == 0 ? widget.firstNumberColor : null,
                ),
              ),
            ),
          ],
        ),
      ));

    _number3DEffect = _number3DEffect.reversed.toList();
  }

  @override
  void initState() {
    super.initState();
    _listOf3DNumbers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordSize());

    setState(() {
      _shader = linearGradient(_numberRenderBox);
    });
  }

  void _recordSize() {
    setState(() {
      _numberRenderBox = _numberGKey.currentContext.findRenderObject();
    });
  }

  @override
  void didUpdateWidget(ClockNumbers oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (linearGradient(_numberRenderBox) != null)
      setState(() {
        _shader = linearGradient(_numberRenderBox);
      });
    if (widget != oldWidget) _listOf3DNumbers();
  }

  @override
  Widget build(BuildContext buildContext) {
    return Positioned.fill(
      top: widget.positionTop,
      left: (widget.positionLeft / 100 * 80) + ((widget.positionLeft * 20 / 100) * widget.animation.value / 100),
      child: Container(
        child: Stack(
          children: _number3DEffect,
        ),
      ),
    );
  }
}

class CenterShadowEffect extends StatelessWidget {
  final Size trueClockBoxSize;
  final double clockSize;
  final Animation<double> shadowAnimation;
  final Color backgroundColor;
  final Color shadowColor;

  CenterShadowEffect({
    Key key,
    this.trueClockBoxSize,
    this.clockSize,
    this.shadowAnimation,
    this.backgroundColor,
    this.shadowColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: -trueClockBoxSize.height / 1.6,
      top: -trueClockBoxSize.height / 1.055,
      child: Transform.rotate(
        angle: 0.8,
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.centerRight,
          children: <Widget>[
            Container(
              width: clockSize * 160 / 100,
              height: (clockSize * 160 / 100) * shadowAnimation.value / 100,
              decoration: BoxDecoration(
                color: backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: clockSize * 70 / 100,
                    offset: Offset(clockSize * 15 / 100, 0),
                  ),
                ],
              ),
            ),
            Container(
              width: trueClockBoxSize.width,
              height: trueClockBoxSize.width,
              color: backgroundColor,
            ),
          ],
        ),
      ),
    );
  }
}
