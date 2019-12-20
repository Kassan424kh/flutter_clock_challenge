import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'provider/data_of_clock_numbers.dart';

class ClockHand extends StatefulWidget {
  final double handWidth;
  final double handHeight;
  final double dotSize;
  final Size clockBoxSize;
  final Offset clockBoxPosition;
  final double positionLeft;
  double positionTop;
  final handColor;

  ClockHand({
    Key key,
    this.handWidth = 0,
    this.handHeight = 0,
    this.dotSize = 0,
    this.handColor = Colors.black26,
    this.clockBoxSize,
    this.positionLeft,
    this.positionTop,
    this.clockBoxPosition,
  }) : super(key: key);

  @override
  _ClockHandState createState() => _ClockHandState();
}

class _ClockHandState extends State<ClockHand> {

  double _positionTop = 2000;

  _setPositionTopOfHand(){
    Timer(const Duration(milliseconds: 3), () {
      if (Provider.of<DataOfClockNumbers>(context).activeMinuteNumberOffset != null) setState(() {
        _positionTop = (Provider.of<DataOfClockNumbers>(context).activeMinuteNumberOffset.dy - widget.positionTop - widget.clockBoxPosition.dy - widget.handHeight) +
            (widget.dotSize + (widget.clockBoxSize.width * 0.4 / 100));
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _setPositionTopOfHand();
  }

  @override
  void didUpdateWidget(ClockHand oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setPositionTopOfHand();
  }
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.positionLeft,
      top: widget.positionTop,
      child: Container(
        width: widget.clockBoxSize.width,
        height: widget.clockBoxSize.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(widget.clockBoxSize.width),
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: _positionTop,
              left: widget.clockBoxSize.width / 2 - (widget.dotSize + (widget.clockBoxSize.width * 0.4 / 100) * 2) / 2,
              child: Container(
                width: widget.dotSize + (widget.clockBoxSize.width * 0.4 / 100) * 2,
                height: widget.handHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(widget.handWidth * 2)),
                  border: Border.all(
                    color: widget.handColor,
                    width: widget.clockBoxSize.width * 0.4 / 100,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
