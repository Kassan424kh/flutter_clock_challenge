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
import 'package:vector_math/vector_math_64.dart' show radians;

enum _Element { primary, hour, minute, centerShadow }

final _lightTheme = {
  _Element.primary: Colors.white,
  _Element.hour: [
    Color(0xff002fff),
    Color(0xff00f4ff),
  ],
  _Element.minute: [
    Color(0xff5F00E5),
    Color(0xffff00d9),
  ],
  _Element.centerShadow: Color(0xff5F00E5),
};
final _darkTheme = {
  _Element.primary: Color(0xff0a0060),
  _Element.hour: [
    Color(0xff002fff),
    Color(0xff00f4ff),
  ],
  _Element.minute: [
    Color(0xff5F00E5),
    Color(0xffff00d9),
  ],
  _Element.centerShadow: Color(0xff5F00E5),
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
  double radiansPerSeconds = radians(360 / 10);
  double radiansPerMinutes = radians(360 / 10);
  double radiansPerHour = radians(360 / 12);
  double _radians = radians(360 / 24);

  Timer _timer;
  GlobalKey _clockBoxKey = GlobalKey();
  Size _clockBoxSize = Size(0, 0);

  /// Need using
  // Offset _clockBoxPosition;

  _getSizes() {
    final RenderBox renderBoxRed = _clockBoxKey.currentContext.findRenderObject();
    final sizeRed = renderBoxRed.size;
    setState(() => _clockBoxSize = sizeRed);
  }

  /// Need using
  /*_getPositions() {
    final RenderBox renderBoxRed = _clockBoxKey.currentContext.findRenderObject();
    final positionRed = renderBoxRed.localToGlobal(Offset.zero);
    setState(() => _clockBoxPosition = positionRed);
  }*/

  _afterLayout(_) {
    _getSizes();

    /// Need using
    //_getPositions();
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
    final colors = Theme.of(context).brightness != Brightness.light ? _lightTheme : _darkTheme;
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
            color: colors[_Element.primary],
            child: Stack(
              children: [
                ClockNumbers(
                  fontSize: clockSize * 1.5,
                  clockNumber: _now.minute,
                  clockBoxSize: clockSize,
                  positionTop: clockSize / 2.5,
                  positionLeft: clockSize * 140 / 100,
                  number3dEffectSize: clockSize * 0.25 / 100,
                  firstNumberColor: colors[_Element.primary],
                  gradientColors: colors[_Element.minute],
                ),
                Positioned(
                  left: -_clockBoxSize.height / 1.7,
                  top: -_clockBoxSize.height / 1.08,
                  child: Transform.rotate(
                    angle: 0.8,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: <Widget>[
                        Container(
                          width: _clockBoxSize.height / 1.4,
                          height: _clockBoxSize.height / 1.4,
                          decoration: BoxDecoration(
                            color: colors[_Element.primary],
                            boxShadow: [
                              BoxShadow(
                                color: (colors[_Element.centerShadow] as Color).withOpacity(0.4),
                                blurRadius: 200,
                                offset: Offset(50, 0),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: _clockBoxSize.width,
                          height: _clockBoxSize.width,
                          color: colors[_Element.primary],
                        ),
                      ],
                    ),
                  ),
                ),
                ClockNumbers(
                  fontSize: clockSize * 1.6,
                  clockNumber: _now.hour,
                  clockBoxSize: clockSize,
                  positionTop: -(clockSize * 20/ 100),
                  positionLeft: clockSize * 5 / 100,
                  number3dEffectSize: clockSize * 0.25 / 100,
                  firstNumberColor: colors[_Element.primary],
                  gradientColors: colors[_Element.hour],
                )
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
  }) : super(key: key);

  @override
  _ClockNumbersState createState() => _ClockNumbersState();
}

class _ClockNumbersState extends State<ClockNumbers> {
  GlobalKey _numberGKey = GlobalKey();
  RenderBox _numberRenderBox;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordSize());
  }

  void _recordSize() {
    setState(() {
      _numberRenderBox = _numberGKey.currentContext.findRenderObject();
    });
  }

  @override
  Widget build(BuildContext buildContext) {
    Shader linearGradient(RenderBox renderBox) {
      if (renderBox == null) return null;
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: widget.gradientColors,
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

    List<Widget> _number3DEffect() {
      List<Widget> _list = [];
      for (var number = 0; number < 40; number++)
        _list.add(Align(
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
                    foreground: number != 0 ? (Paint()..shader = linearGradient(_numberRenderBox)) : null,
                    color: number == 0 ? widget.firstNumberColor : null,
                  ),
                ),
              ),
            ],
          ),
        ));

      _list = _list.reversed.toList();

      return _list;
    }

    return Positioned.fill(
      top: widget.positionTop,
      left: widget.positionLeft,
      child: Container(
        child: Stack(
          children: _number3DEffect(),
        ),
      ),
    );
  }
}
