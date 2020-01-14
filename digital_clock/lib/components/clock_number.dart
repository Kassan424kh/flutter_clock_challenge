import 'package:flutter/material.dart';

class ClockNumbers extends StatefulWidget {
  final int clockNumber;
  final double clockBoxSize;
  final double positionTop, positionLeft;
  final double fontSize;
  final double number3dEffectSize;
  final Color firstNumberColor;
  final List<Color> gradientColors;
  final bool isTypeHour;
  final Animation animation;

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
    this.animation,
  }) : super(key: key);

  @override
  _ClockNumbersState createState() => _ClockNumbersState();
}

class _ClockNumbersState extends State<ClockNumbers> {
  GlobalKey _numberGKey = GlobalKey();
  RenderBox _numberRenderBox;
  List<Widget> _number3DEffect = [];
  Shader _shader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.transparent, Colors.transparent],
    stops: [0.0, 1.0],
    tileMode: TileMode.clamp,
  ).createShader(
    Rect.fromCircle(
      center: Offset(0, 0),
      radius: 300,
    ),
  );

  Shader linearGradient(RenderBox renderBox) {
    if (renderBox == null) return null;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: widget.gradientColors.map((color) {
        return color.withOpacity(widget.animation.value / 100);
      }).toList(),
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

  _listOf3DNumbers() {
    _number3DEffect.clear();
    for (var number = 0; number < 40; number++)
      _number3DEffect.add(Align(
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
                  foreground: number != 0 ? (Paint()..shader = _shader) : null,
                  color: number == 0 ? widget.firstNumberColor : null,
                ),
              ),
            ),
          ],
        ),
      ));

    _number3DEffect = _number3DEffect.reversed.toList();
  }

  @override
  void initState() {
    super.initState();
    _listOf3DNumbers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordSize());

    setState(() {
      _shader = linearGradient(_numberRenderBox);
    });
  }

  void _recordSize() {
    setState(() {
      _numberRenderBox = _numberGKey.currentContext.findRenderObject();
    });
  }

  @override
  void didUpdateWidget(ClockNumbers oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (linearGradient(_numberRenderBox) != null)
      setState(() {
        _shader = linearGradient(_numberRenderBox);
      });
    if (widget != oldWidget) _listOf3DNumbers();
  }

  @override
  Widget build(BuildContext buildContext) {
    return Positioned.fill(
      top: widget.positionTop,
      left: (widget.positionLeft / 100 * 80) + ((widget.positionLeft * 20 / 100) * widget.animation.value / 100),
      child: Container(
        child: Stack(
          children: _number3DEffect,
        ),
      ),
    );
  }
}