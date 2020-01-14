import 'dart:math';
import 'dart:ui';
import 'dart:async';

import 'package:digital_clock/center_shadow_effect.dart';
import 'package:digital_clock/clock_data_text.dart';
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
  // variables
  var _now = DateTime.now();

  int _nowHourFormat = 24;
  int _nowHour = DateTime.now().hour;
  int _nowMinute = DateTime.now().minute;

  double _calculatedClockSize = 0;

  Timer _timer;
  GlobalKey _clockBoxKey = GlobalKey();
  Size _clockBoxSize = Size(0, 0);

  AnimationController _animationControllerShadowEffect, _animationControllerHour, _animationControllerMinute, _animationController12ClockFormat;
  Animation<double> _shadowAnimation, _hourAnimation, _minuteAnimation, _12ClockFormatAnimation;

  @override
  void initState() {
    super.initState();
    _updateTime();

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
    _animationController12ClockFormat = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
      reverseDuration: Duration(milliseconds: 400),
    );

    _shadowAnimation = _animationTweens(_animationControllerShadowEffect);
    _hourAnimation = _animationTweens(_animationControllerHour);
    _minuteAnimation = _animationTweens(_animationControllerMinute);
    _12ClockFormatAnimation = _animationTweens(_animationController12ClockFormat);

    _animationControllerShadowEffect.forward().whenCompleteOrCancel(() {
      Timer(Duration(milliseconds: 300), () {
        if (!widget.model.is24HourFormat) _animationController12ClockFormat.forward();
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
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // functions
  _getSizes(_) {
    final RenderBox renderBoxRed = _clockBoxKey.currentContext.findRenderObject();
    final sizeRed = renderBoxRed.size;

    setState(() {
      _clockBoxSize = sizeRed;
    });
  }

  _updateNumbersAnimation() {
    // update Hour Animation
    if (_animationControllerHour != null && _animationControllerHour.isCompleted && _animationControllerShadowEffect.isCompleted && _now.minute == 59 && _now.second == 59 ||
        _now.hour != _nowHour ||
        (_nowHourFormat == 24 && !widget.model.is24HourFormat || _nowHourFormat == 12 && widget.model.is24HourFormat)) {
      _animationControllerHour.reverse().whenCompleteOrCancel(() {
        setState(() {
          _nowHour = widget.model.is24HourFormat ? _nowHour : _nowHour > 12 ? _nowHour - 12 : _nowHour;
          _nowHourFormat = _nowHourFormat == 12 ? 24 : 12;
        });
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

    if (_animationController12ClockFormat != null) {
      if (!widget.model.is24HourFormat) {
        _animationController12ClockFormat.forward();
      } else
        _animationController12ClockFormat.reverse();
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

    return Semantics.fromProperties(
      properties: SemanticsProperties(
        label: 'Digital clock with time $time',
        value: time,
      ),
      child: Container(
        key: _clockBoxKey,
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
            ClockDataText(
              fontSize: _calculatedClockSize * 15 / 100,
              clockDataText: _nowHour <= 12 ? "AM" : "PM",
              clockBoxSize: _calculatedClockSize,
              positionTop: _calculatedClockSize * 123 / 100,
              positionLeft: _calculatedClockSize * 90 / 100,
              dataText3dEffectSize: _calculatedClockSize * 0.05 / 100,
              firstDataTextLayserColor: colors[_Element.primary],
              gradientColors: colors[_Element.hour],
              animation: _12ClockFormatAnimation,
            ),
          ],
        ),
      ),
    );
  }
}
