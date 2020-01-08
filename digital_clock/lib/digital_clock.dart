import 'dart:async';

import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';

enum _Element {
  background,
  text,
  shadow,
}

final _lightTheme = {
  _Element.background: Color(0xFF81B3FE),
  _Element.text: Colors.white,
  _Element.shadow: Colors.black,
};

final _darkTheme = {
  _Element.background: Colors.black,
  _Element.text: Colors.white,
  _Element.shadow: Color(0xFF174EA6),
};

class DigitalClock extends StatefulWidget {
  const DigitalClock(this.model);

  final ClockModel model;

  @override
  _DigitalClockState createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock> {
  DateTime _dateTime = DateTime.now();
  Timer _timer;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    _updateTime();
    _updateModel();
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
    widget.model.dispose();
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      // Cause the clock to rebuild when the model changes.
    });
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateTime.now();
      _timer = Timer(
        Duration(minutes: 1) - Duration(seconds: _dateTime.second) - Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).brightness == Brightness.light ? _lightTheme : _darkTheme;

    return Container(
      child: ClockNumbers(),
    );
  }
}

class ClockNumbers extends StatelessWidget {
  @override
  Widget build(BuildContext buildContext) {
    final Shader linearGradient = LinearGradient(
      colors: <Color>[Color(0xffDA44bb), Color(0xff8921aa)],
    ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0));

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
                    fontSize: 400,
                    foreground: number != 0 ? (Paint()..shader = linearGradient) : null,
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
