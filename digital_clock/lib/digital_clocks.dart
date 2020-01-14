import 'dart:ui';
import 'dart:async';

import 'package:digital_clock/components/center_shadow_effect.dart';
import 'package:digital_clock/components/clock_data_text.dart';
import 'package:digital_clock/components/clock_number.dart';
import 'package:digital_clock/styling/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';

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
  Animation<double> _shadowAnimation, _hourAnimation, _minuteAnimation, _clockFormatAnimation;

  @override
  void initState() {
    super.initState();
    _updateTime();

    // set animation controllers
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

    // animation function
    Animation _animationTween(AnimationController ac) => Tween(begin: 0.0, end: 100.0).animate(
          CurvedAnimation(parent: ac, curve: Curves.easeInOutCubic),
        )..addListener(() => setState(() {}));

    // set animation Tween
    _shadowAnimation = _animationTween(_animationControllerShadowEffect);
    _hourAnimation = _animationTween(_animationControllerHour);
    _minuteAnimation = _animationTween(_animationControllerMinute);
    _clockFormatAnimation = _animationTween(_animationController12ClockFormat);

    // run animation on start the app
    _animationControllerShadowEffect.forward().whenCompleteOrCancel(() {
      Timer(Duration(milliseconds: 300), () {
        if (!widget.model.is24HourFormat) _animationController12ClockFormat.forward();
        _animationControllerHour.forward().whenCompleteOrCancel(() {
          _animationControllerMinute.forward();
        });
      });
    });

    // set Clock box size
    WidgetsBinding.instance.addPostFrameCallback(_getSizes);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // functions
  // size function setter
  _getSizes(_) {
    final RenderBox renderBoxRed = _clockBoxKey.currentContext.findRenderObject();
    final sizeRed = renderBoxRed.size;

    setState(() {
      _clockBoxSize = sizeRed;
    });
  }

  // function animating number updater
  _updateNumbersAnimation() {
    int _nowHour12Or24Format = widget.model.is24HourFormat ? _now.hour : _now.hour > 12 ? _now.hour - 12 : _now.hour;

    // update Hour Animation
    if (_animationControllerHour != null && _animationControllerHour.isCompleted && _animationControllerShadowEffect.isCompleted && _now.minute == 59 && _now.second == 59 ||
        _nowHour12Or24Format != _nowHour ||
        (_nowHourFormat == 24 && !widget.model.is24HourFormat || _nowHourFormat == 12 && widget.model.is24HourFormat)) {
      _animationControllerHour.reverse().whenCompleteOrCancel(() {
        setState(() {
          _nowHour = widget.model.is24HourFormat ? _now.hour : _now.hour > 12 ? _now.hour - 12 : _now.hour; // set hour to selected format (12 or 24)
          if (_nowHourFormat == 24 && !widget.model.is24HourFormat || _nowHourFormat == 12 && widget.model.is24HourFormat) _nowHourFormat = _nowHourFormat == 12 ? 24 : 12;
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

  // time updater
  void _updateTime() {
    // update times, when it should updated
    _updateNumbersAnimation();

    // update time
    setState(() {
      _now = DateTime.now();
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _now.millisecond),
        _updateTime,
      );
    });

    // set size if screen would be scaled/resized
    Timer(Duration(milliseconds: 200), () {
      WidgetsBinding.instance.addPostFrameCallback(_getSizes);
      setState(() {
        _calculatedClockSize = _clockBoxSize.height / 2;
      });
    });
  }

  // function percent calculator after _calculatedClockSize
  double _calculateAfterPercent(double percent) => _calculatedClockSize * percent / 100;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).brightness == Brightness.light ? ClockColorThemes.lightTheme : ClockColorThemes.darkTheme;
    final time = DateFormat.Hms().format(DateTime.now());

    return Semantics.fromProperties(
      properties: SemanticsProperties(
        label: 'Digital clock with time $time',
        value: time,
      ),
      child: OverflowBox(
        child: Container(
          key: _clockBoxKey,
          width: _clockBoxSize.width,
          height: _clockBoxSize.height,
          color: colors[ElementColor.primary],
          child: Stack(
            overflow: Overflow.clip,
            children: [
              // Minute
              ClockNumbers(
                fontSize: _calculateAfterPercent(140),
                clockNumber: _nowMinute,
                clockBoxSize: _calculatedClockSize,
                positionTop: _calculateAfterPercent(50),
                positionLeft: _calculateAfterPercent(140),
                number3dEffectSize: _calculateAfterPercent(0.25),
                firstNumberColor: colors[ElementColor.primary],
                gradientColors: colors[ElementColor.minute],
                animation: _minuteAnimation,
              ),
              // Centered Shadow
              CenterShadowEffect(
                trueClockBoxSize: _clockBoxSize,
                clockSize: _calculatedClockSize,
                backgroundColor: colors[ElementColor.primary],
                shadowColor: colors[ElementColor.centerShadow],
                shadowAnimation: _shadowAnimation,
              ),
              // Hour
              ClockNumbers(
                fontSize: _calculateAfterPercent(150),
                clockNumber: _nowHour,
                clockBoxSize: _calculatedClockSize,
                positionTop: _calculateAfterPercent(0),
                positionLeft: _calculateAfterPercent(30),
                number3dEffectSize: _calculateAfterPercent(0.25),
                firstNumberColor: colors[ElementColor.primary],
                gradientColors: colors[ElementColor.hour],
                animation: _hourAnimation,
              ),
              // Hour Format (12 or 24)
              ClockDataText(
                fontSize: _calculateAfterPercent(15),
                clockDataText: _now.hour <= 12 ? "AM" : "PM",
                clockBoxSize: _calculatedClockSize,
                positionTop: _calculateAfterPercent(136),
                positionLeft: _calculateAfterPercent(80),
                dataText3dEffectSize: _calculateAfterPercent(0.05),
                firstDataTextLayserColor: colors[ElementColor.primary],
                gradientColors: colors[ElementColor.hour],
                animation: _clockFormatAnimation,
              ),
              // Date yyyy.mm.dd
              ClockDataText(
                fontSize: _calculateAfterPercent(15),
                clockDataText: "${widget.model.temperatureString}  ${DateFormat("dd-MM-yyyy").format(DateTime.now())}",
                clockBoxSize: _calculatedClockSize,
                positionTop: _calculateAfterPercent(180),
                positionLeft: _calculateAfterPercent(220),
                dataText3dEffectSize: _calculateAfterPercent(0.05),
                firstDataTextLayserColor: colors[ElementColor.date],
                gradientColors: [colors[ElementColor.primary], colors[ElementColor.primary]],
                animation: _shadowAnimation,
                lightFount: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
