import 'dart:math';
import 'dart:ui';
import 'dart:async';

import 'package:digital_clock/center_shadow_effect.dart';
import 'package:digital_clock/clock_number.dart';
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
  _Element.centerShadow: Color(0xff6F0FFF).withOpacity(0.3),
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
  _Element.centerShadow: Color(0xff6F0FFF).withOpacity(0.5),
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

  int _nowHour = DateTime.now().hour;
  int _nowMinute = DateTime.now().minute;

  double _calculatedClockSize = 0;

  Timer _timer;
  GlobalKey _clockBoxKey = GlobalKey();
  Size _clockBoxSize = Size(0, 0);

  AnimationController _animationControllerShadowEffect, _animationControllerHour, _animationControllerMinute;
  Animation<double> _shadowAnimation, _hourAnimation, _minuteAnimation;

  _getSizes(_) {
    final RenderBox renderBoxRed = _clockBoxKey.currentContext.findRenderObject();
    final sizeRed = renderBoxRed.size;

    setState(() {
      _clockBoxSize = sizeRed;
    });
  }

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    _updateTime();
    _updateModel();

    Animation _animationTweens(AnimationController ac) => Tween(begin: 0.0, end: 100.0).animate(
          CurvedAnimation(parent: ac, curve: Curves.easeInOutCubic),
        )..addListener(() => setState(() {}));

    _animationControllerShadowEffect = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    _animationControllerHour = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
      reverseDuration: Duration(milliseconds: 400),
    );
    _animationControllerMinute = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
      reverseDuration: Duration(milliseconds: 400),
    );

    _shadowAnimation = _animationTweens(_animationControllerShadowEffect);
    _hourAnimation = _animationTweens(_animationControllerHour);
    _minuteAnimation = _animationTweens(_animationControllerMinute);

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

  _updateNumbersAnimation() {
    // update Hour Animation
    if (_animationControllerHour != null && _animationControllerHour.isCompleted && _animationControllerShadowEffect.isCompleted && _now.minute == 59 && _now.second == 59 || _now.hour != _nowHour) {
      _animationControllerHour.reverse().whenCompleteOrCancel(() {
        setState(() => _nowHour = _now.hour);
        Timer(Duration(milliseconds: 50), () => _animationControllerHour.forward(from: 0));
      });
    }

    // update Minute Animation
    if (_animationControllerMinute != null && _animationControllerMinute.isCompleted && _animationControllerShadowEffect.isCompleted && _now.second == 59 || _now.minute != _nowMinute) {
      _animationControllerMinute.reverse().whenCompleteOrCancel(() {
        setState(() => _nowMinute = _now.minute);
        Timer(Duration(milliseconds: 50), () => _animationControllerMinute.forward(from: 0));
      });
    }
  }

  void _updateTime() {
    _updateNumbersAnimation();
    setState(() {
      _now = DateTime.now();
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _now.millisecond),
        _updateTime,
      );
    });

    Timer(Duration(milliseconds: 500), () {
      WidgetsBinding.instance.addPostFrameCallback(_getSizes);
      setState(() {
        _calculatedClockSize = _clockBoxSize.height / 2;
      });
    });
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
                  fontSize: _calculatedClockSize * 1.4,
                  clockNumber: _nowMinute,
                  clockBoxSize: _calculatedClockSize,
                  positionTop: _calculatedClockSize / 2.8,
                  positionLeft: _calculatedClockSize * 120 / 100,
                  number3dEffectSize: _calculatedClockSize * 0.25 / 100,
                  firstNumberColor: colors[_Element.primary],
                  gradientColors: colors[_Element.minute],
                  animation: _minuteAnimation,
                ),
                CenterShadowEffect(
                  trueClockBoxSize: _clockBoxSize,
                  clockSize: _calculatedClockSize,
                  shadowAnimation: _shadowAnimation,
                  backgroundColor: colors[_Element.primary],
                  shadowColor: colors[_Element.centerShadow],
                ),
                ClockNumbers(
                  fontSize: _calculatedClockSize * 1.4,
                  clockNumber: _nowHour,
                  clockBoxSize: _calculatedClockSize,
                  positionTop: -(_calculatedClockSize * 20 / 100),
                  positionLeft: _calculatedClockSize * 4 / 100,
                  number3dEffectSize: _calculatedClockSize * 0.25 / 100,
                  firstNumberColor: colors[_Element.primary],
                  gradientColors: colors[_Element.hour],
                  animation: _hourAnimation,
                ),
                /*BackgroundAnimations(
                  clockBoxSize: _clockBoxSize,
                )*/
              ],
            ),
          )
        ],
      ),
    );
  }
}

class BackgroundAnimations extends StatelessWidget {
  final _random = new Random();

  double next(double min, double max) => min + (max - min) * _random.nextDouble();

  final Size clockBoxSize;

  BackgroundAnimations({Key key, this.clockBoxSize}) : super(key: key);

  List<Widget> get _listOfAnimatedBackgroundWidgets {
    List<Widget> _list = [];
    for (int animatedWidget = 0; animatedWidget <= 3; animatedWidget++)
      _list.add(
        Positioned(
          top: next(
            (clockBoxSize.width * 5 / 100),
            (clockBoxSize.height.toDouble() - (clockBoxSize.width * 5 / 100) * 2),
          ),
          child: Container(
              width: clockBoxSize.width * 15 / 100,
              height: clockBoxSize.width * 5 / 100,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(clockBoxSize.width * 5 / 100)),
                  border: Border.all(color: Colors.greenAccent, width: clockBoxSize.width * .5 / 100, style: BorderStyle.solid))),
        ),
      );
    return _list;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        width: clockBoxSize.width,
        height: clockBoxSize.height,
        color: Colors.white,
        child: Stack(
          children: _listOfAnimatedBackgroundWidgets,
        ),
      ),
    );
  }
}
