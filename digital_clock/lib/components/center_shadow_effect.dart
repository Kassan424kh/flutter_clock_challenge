import 'package:flutter/material.dart';

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
      top: -trueClockBoxSize.height,
      child: Transform.rotate(
        angle: 0.8,
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.centerRight,
          children: <Widget>[
            Container(
              width: clockSize * 140 / 100,
              height: (clockSize * 120 / 100) * shadowAnimation.value / 100,
              decoration: BoxDecoration(
                color: backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: clockSize * 50 / 100,
                    offset: Offset(clockSize * 15 / 100, 0),
                  ),
                ],
              ),
            ),
            Container(
              width: trueClockBoxSize.width,
              height: trueClockBoxSize.width * 110 / 100,
              color: backgroundColor,
            ),
          ],
        ),
      ),
    );
  }
}