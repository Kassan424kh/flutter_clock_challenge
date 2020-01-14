import 'package:flutter/material.dart';

class ClockDataText extends StatefulWidget {
  final String clockDataText;
  final double clockBoxSize;
  final double positionTop, positionLeft;
  final double fontSize;
  final double dataText3dEffectSize;
  final Color firstDataTextLayserColor;
  final List<Color> gradientColors;
  final Animation animation;
  final bool lightFount;

  ClockDataText({
    Key key,
    this.fontSize,
    this.clockDataText,
    this.clockBoxSize,
    this.positionTop,
    this.positionLeft,
    this.dataText3dEffectSize = 0.5,
    this.gradientColors,
    this.firstDataTextLayserColor,
    this.animation,
    this.lightFount = false,
  }) : super(key: key);

  @override
  _ClockDataTextState createState() => _ClockDataTextState();
}

class _ClockDataTextState extends State<ClockDataText> {
  GlobalKey _numberGKey = GlobalKey();
  RenderBox _dataTextRenderBox;
  List<Widget> _dataText3DEffect = [];
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

  _listOf3DDataText() {
    _dataText3DEffect.clear();
    for (var dataText = 0; dataText < 20; dataText++)
      _dataText3DEffect.add(Align(
        alignment: Alignment.topCenter,
        child: Stack(
          children: <Widget>[
            Container(),
            Positioned(
              top: (widget.dataText3dEffectSize * dataText).toDouble(),
              left: (widget.dataText3dEffectSize * dataText).toDouble(),
              child: Text(
                widget.clockDataText,
                key: dataText == 0 ? _numberGKey : null,
                textScaleFactor: 0.8,
                style: TextStyle(
                  fontFamily: "ubuntu",
                  fontWeight: !widget.lightFount ? FontWeight.w700 : null,
                  fontSize: widget.fontSize,
                  foreground: dataText != 0 ? (Paint()..shader = _shader) : null,
                  color: dataText == 0 ? widget.firstDataTextLayserColor : null,
                ),
              ),
            ),
          ],
        ),
      ));

    _dataText3DEffect = _dataText3DEffect.reversed.toList();
  }

  @override
  void initState() {
    super.initState();
    _listOf3DDataText();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordSize());

    setState(() {
      _shader = linearGradient(_dataTextRenderBox);
    });
  }

  void _recordSize() {
    setState(() {
      _dataTextRenderBox = _numberGKey.currentContext.findRenderObject();
    });
  }

  @override
  void didUpdateWidget(ClockDataText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (linearGradient(_dataTextRenderBox) != null)
      setState(() {
        _shader = linearGradient(_dataTextRenderBox);
      });
    if (widget != oldWidget) _listOf3DDataText();
  }

  @override
  Widget build(BuildContext buildContext) {
    return Positioned.fill(
      top: widget.positionTop,
      left: widget.positionLeft != null ? (widget.positionLeft / 100 * 95) + ((widget.positionLeft * 5 / 100) * widget.animation.value / 100) : null,
      child: Container(
        child: Stack(
          children: _dataText3DEffect,
        ),
      ),
    );
  }
}
