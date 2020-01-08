import 'dart:async';

import 'package:flutter/material.dart';

import 'provider/data_of_clock_numbers.dart';
import 'package:provider/provider.dart';

class ClockNumbers extends StatefulWidget {
  final double opacity;
  final bool is24HourFormat;
  final Size displaySize;
  final double numbersSize;
  final int nowType;
  final double radians;
  final double clockSize;
  final AnimationController animationController;
  final Animation<double> animation;
  final bool isHour;
  final double nowNumberSize;
  final double notNowNumberSize;
  final Color nowNumberColor;
  final Color notNowNumberColor;
  final Color backgroundColor;
  final List<BoxShadow> numberShadows;
  final List<BoxShadow> boxShadow;
  final double spaceBetweenNumberAndDot;
  final double dotsSize;
  final bool isDirectionNumbersLeft;
  final double positionLeft;
  final double positionTop;
  final Gradient backgroundGradientColor;

  ClockNumbers({
    Key key,
    this.opacity = 1,
    this.is24HourFormat = false,
    this.displaySize,
    this.nowType,
    this.radians,
    this.clockSize,
    this.animationController,
    this.animation,
    this.isHour = false,
    this.nowNumberSize,
    this.notNowNumberSize,
    this.nowNumberColor,
    this.backgroundColor,
    this.numberShadows,
    this.spaceBetweenNumberAndDot,
    this.dotsSize,
    this.numbersSize,
    this.isDirectionNumbersLeft,
    this.positionLeft,
    this.positionTop,
    this.backgroundGradientColor,
    this.boxShadow,
    this.notNowNumberColor,
  }) : super(key: key);

  @override
  _ClockNumbersState createState() => _ClockNumbersState();
}

class _ClockNumbersState extends State<ClockNumbers> {
  int _nowMinute = DateTime.now().minute;
  GlobalKey _activeMinutePointKey = GlobalKey();

  _getPositions(_) {
    Timer(const Duration(milliseconds: 10), () {
      if (_activeMinutePointKey.currentContext != null) {
        final RenderBox renderBoxRed = _activeMinutePointKey.currentContext.findRenderObject();
        final positionRed = renderBoxRed.localToGlobal(Offset.zero);
        Provider.of<DataOfClockNumbers>(context).setActiveMinuteNumberOffset(positionRed);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_getPositions);
  }

  @override
  void didUpdateWidget(ClockNumbers oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      _nowMinute = DateTime.now().minute;
    });
    if (widget.displaySize != oldWidget.displaySize) WidgetsBinding.instance.addPostFrameCallback(_getPositions);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> listOfNumbers() {
      List<Widget> allNumbers = [];

      for (var number = 0; number < (widget.isHour ? widget.is24HourFormat ? 24 : 12 : 60); number++) {
        bool checkQuestion = !widget.isHour ? ((number <= _nowMinute + 5) && (number >= _nowMinute - 5) || (_nowMinute < 5 && (number < 5 || number > 56) || _nowMinute >= 55 && number < 3)) : false;
        allNumbers.add(
          checkQuestion || widget.isHour
              ? Align(
                  alignment: Alignment.topCenter,
                  child: Transform.rotate(
                    alignment: Alignment.topCenter,
                    angle: widget.isDirectionNumbersLeft ? -(widget.radians * number) : (widget.radians * number),
                    origin: Offset(0, widget.clockSize / 2),
                    child: Container(
                      width: widget.numbersSize,
                      height: widget.clockSize,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          widget.isHour ? SizedBox(
                            height: widget.spaceBetweenNumberAndDot,
                          ): Container(),
                          !widget.isHour ? SizedBox(
                            height: widget.spaceBetweenNumberAndDot / 2,
                          ): Container(),
                          AnimatedOpacity(
                            opacity: number == widget.nowType ? 1 : widget.opacity,
                            duration: Duration(milliseconds: 350),
                            child: Text(
                              (widget.isHour && number == 0 ? widget.is24HourFormat ? 24 : 12 : number).toString(),

                              style: TextStyle(
                                fontSize: number == widget.nowType ? widget.nowNumberSize : widget.notNowNumberSize,
                                fontFamily: "Gruppo",
                                height: 0,
                                fontWeight: FontWeight.w700,
                                color: number == widget.nowType ? widget.nowNumberColor : widget.notNowNumberColor,
                                shadows: widget.numberShadows,
                              ),
                            ),
                          ),
                          widget.isHour
                              ? SizedBox(
                                  height: widget.spaceBetweenNumberAndDot,
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  ),
                )
              : Container(),
        );
      }

      return allNumbers;
    }

    return Positioned(
      left: widget.positionLeft,
      top: widget.positionTop,
      child: Container(
        width: widget.clockSize,
        height: widget.clockSize,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          gradient: widget.backgroundGradientColor,
          boxShadow: widget.boxShadow,
          borderRadius: BorderRadius.all(
            Radius.circular(widget.clockSize),
          ),
        ),
        child: AnimatedBuilder(
          animation: widget.animationController,
          child: Container(
            width: widget.clockSize,
            height: widget.clockSize,
            child: Stack(children: listOfNumbers()),
          ),
          builder: (BuildContext context, Widget _widget) {
            double checkQuestion = widget.isHour
                ? widget.isDirectionNumbersLeft
                    ? widget.radians * widget.animation.value
                    : -(widget.radians * widget.animation.value)
                : widget.isDirectionNumbersLeft ? (widget.radians * widget.animation.value) : -(widget.radians * widget.animation.value);
            return Transform.rotate(
              alignment: Alignment.center,
              angle: checkQuestion,
              child: _widget,
            );
          },
        ),
      ),
    );
  }
}
