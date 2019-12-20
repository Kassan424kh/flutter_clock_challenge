import 'dart:async';

import 'package:flutter/material.dart';

import 'provider/data_of_clock_numbers.dart';
import 'package:provider/provider.dart';

class ClockNumbers extends StatefulWidget {
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
  final isHour;
  final nowNumberSize;
  final notNowNumberSize;
  final numbersColor;
  final backgroundColor;
  final numberShadows;
  final spaceBetweenNumberAndDot;
  final dotsSize;
  final isDirectionNumbersLeft;
  final positionLeft;
  final positionTop;

  ClockNumbers({
    Key key,
    this.opacity,
    this.is24HourFormat = false,
    this.displaySize,
    this.nowType,
    this.radians,
    this.clockSize,
    this.showQuestion = false,
    this.animationController,
    this.animation,
    this.isHour = false,
    this.nowNumberSize,
    this.notNowNumberSize,
    this.numbersColor,
    this.backgroundColor,
    this.numberShadows,
    this.spaceBetweenNumberAndDot,
    this.dotsSize,
    this.numbersSize,
    this.isDirectionNumbersLeft,
    this.positionLeft,
    this.positionTop,
  }) : super(key: key);

  @override
  _ClockNumbersState createState() => _ClockNumbersState();
}

class _ClockNumbersState extends State<ClockNumbers> {
  int _nowMinute = DateTime.now().minute;
  GlobalKey _activeMinutePointKey = GlobalKey();

  _getPositions(_) {
    Timer(const Duration(milliseconds: 10), () {
      final RenderBox renderBoxRed = _activeMinutePointKey.currentContext.findRenderObject();
      final positionRed = renderBoxRed.localToGlobal(Offset.zero);
      Provider.of<DataOfClockNumbers>(context).setActiveMinuteNumberOffset(positionRed);
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
    WidgetsBinding.instance.addPostFrameCallback(_getPositions);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback(_getPositions);
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
                          SizedBox(height: 10),
                          !widget.isHour
                              ? AnimatedOpacity(
                                  opacity: number == widget.nowType ? 1 : widget.opacity,
                                  duration: Duration(milliseconds: 350),
                                  child: Container(
                                    key: !widget.isHour && number == _nowMinute ? _activeMinutePointKey : Key(number.toString()),
                                    height: widget.dotsSize,
                                    width: widget.dotsSize,
                                    decoration: BoxDecoration(
                                      color: widget.numbersColor,
                                      borderRadius: BorderRadius.all(Radius.circular(20)),
                                    ),
                                  ),
                                )
                              : Container(),
                          SizedBox(
                            height: widget.spaceBetweenNumberAndDot,
                          ),
                          AnimatedOpacity(
                            opacity: number == widget.nowType ? 1 : widget.opacity,
                            duration: Duration(milliseconds: 350),
                            child: Text(
                              (widget.isHour && number == 0 ? widget.is24HourFormat ? 24 : 12 : number).toString(),
                              style: TextStyle(
                                fontSize: number == widget.nowType ? widget.nowNumberSize : widget.notNowNumberSize,
                                fontFamily: "Gruppo",
                                fontWeight: FontWeight.w700,
                                color: widget.numbersColor,
                                shadows: widget.numberShadows,
                              ),
                            ),
                          ),
                          widget.isHour
                              ? SizedBox(
                                  height: widget.spaceBetweenNumberAndDot,
                                )
                              : Container(),
                          widget.isHour
                              ? AnimatedOpacity(
                                  opacity: number == widget.nowType ? 1 : widget.opacity,
                                  duration: Duration(milliseconds: 350),
                                  child: Container(
                                    height: widget.dotsSize,
                                    width: widget.dotsSize,
                                    decoration: BoxDecoration(
                                      color: widget.numbersColor,
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
      }

      return allNumbers;
    }

    return Positioned(
      left: widget.positionLeft,
      top: widget.positionTop,
      child: AnimatedBuilder(
        animation: widget.animationController,
        child: Container(
          width: widget.clockSize,
          height: widget.clockSize,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.all(
              Radius.circular(widget.clockSize),
            ),
          ),
          child: Stack(children: listOfNumbers()),
        ),
        builder: (BuildContext context, Widget _widget) {
          double checkQuestion = widget.isHour
              ? widget.isDirectionNumbersLeft
                  ? widget.radians * (widget.animation.value + double.parse((_nowMinute / 60 * 100).toStringAsFixed(0)) / 100)
                  : -(widget.radians * (widget.animation.value + double.parse((_nowMinute / 60 * 100).toStringAsFixed(0)) / 100))
              : widget.isDirectionNumbersLeft ? (widget.radians * widget.animation.value) : -(widget.radians * widget.animation.value);
          return Transform.rotate(
            alignment: Alignment.center,
            angle: checkQuestion,
            child: _widget,
          );
        },
      ),
    );
  }
}
