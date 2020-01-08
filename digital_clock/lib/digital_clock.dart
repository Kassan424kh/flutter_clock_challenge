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

class DigitalClock extends StatefulWidget {
  const DigitalClock(this.model);

  final ClockModel model;

  @override
  _DigitalClockState createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock>
    with TickerProviderStateMixin {
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
    final RenderBox renderBoxRed =
        _clockBoxKey.currentContext.findRenderObject();
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

    print(clockSize);
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
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : Colors.black87,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: weatherInfo,
                  ),
                ),
                ClockNumbers(fontSize: clockSize,)
              ],
            ),
          )
        ],
      ),
    );
  }
}

class ClockNumbers extends StatelessWidget {
  final int clockNumber;
  final double fontSize;

  ClockNumbers({
    Key key,
    this.fontSize,
    this.clockNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext buildContext) {
    final Shader linearGradient = LinearGradient(
      colors: <Color>[Color(0xff8921aa), Color(0xffDA44bb)],
    ).createShader(Rect.fromCircle(center: Offset(0, 0), radius: 300));

    List<Widget> _number3DEffect() {
      List<Widget> _list = [];
      for (var number = 0; number < 40; number++)
        _list.add(Align(
          alignment: Alignment.topCenter,
          child: Stack(
            children: <Widget>[
              Positioned(
                top: (1 * number).toDouble(),
                left: (1 * number).toDouble(),
                child: Text(
                  55.toString(),
                  style: TextStyle(
                    fontFamily: "ubuntu_bold_italic",
                    fontSize: fontSize,
                    foreground:
                        number != 0 ? (Paint()..shader = linearGradient) : null,
                    color: number == 0 ? Colors.white : null,
                  ),
                ),
              ),
            ],
          ),
        ));

      _list = _list.reversed.toList();

      return _list;
    }

    return Container(
      child: Stack(
        alignment: Alignment.center,
        children: _number3DEffect(),
      ),
    );
  }
}
