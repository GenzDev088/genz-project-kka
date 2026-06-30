import 'package:flutter/material.dart';

class SubtitleText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color strokeColor;
  final Color backgroundColor;
  final double strokeWidth;
  final double backgroundTransparency;
  final bool enableShadows;

  const SubtitleText({
    super.key,
    required this.text,
    required this.style,
    required this.strokeColor,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.backgroundTransparency,
    this.enableShadows = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor.withAlpha((backgroundTransparency * 255).toInt()),
      child: Stack(
        children: [

          Text(
            text,
            style: style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..color = strokeColor
                ..strokeWidth = strokeWidth,
            ),
            textAlign: TextAlign.center,
          ),


          Text(
            text,
            style: style.copyWith(
              shadows: enableShadows
                  ? [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 3.5,
                        offset: Offset(1, 1),
                      ),
                    ]
                  : null,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
