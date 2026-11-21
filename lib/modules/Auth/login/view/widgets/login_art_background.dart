
import 'package:flutter/material.dart';

class LoginArtBackground extends StatelessWidget {
  final bool isDark;

  const LoginArtBackground({
    super.key,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Background decorative curves
            Positioned.fill(
              child: CustomPaint(
                painter: _LoginCurvesPainter(
                  isDark: isDark,
                ),
              ),
            ),

            // Top-right wheat watermark
            Positioned(
              top: 25,
              right: -12,
              child: Opacity(
                opacity: isDark ? 0.12 : 0.24,
                child: SizedBox(
                  width: 140,
                  height: 200,
                  child: Image.asset(
                    'assets/images/bg_img.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // Bottom-left wheat watermark
            Positioned(
              bottom: 8,
              left: -20,
              child: Transform.rotate(
                angle: -0.15,
                child: Opacity(
                  opacity: isDark ? 0.12 : 0.23,
                  child: SizedBox(
                    width: 135,
                    height: 210,
                    child: Image.asset(
                      'assets/images/bg_img.png',
                      fit: BoxFit.contain,
                    ),
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

class _LoginCurvesPainter extends CustomPainter {
  final bool isDark;

  _LoginCurvesPainter({
    required this.isDark,
  });

  Color _color(Color color) {
    if (!isDark) return color;

    return Color.lerp(
      color,
      const Color(0xFF242424),
      0.65,
    )!;
  }

  Paint _solidPaint(Color color) {
    return Paint()
      ..color = _color(color)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
  }

  Paint _gradientPaint(
      Rect rect,
      List<Color> colors, {
        Alignment begin = Alignment.topLeft,
        Alignment end = Alignment.bottomRight,
      }) {
    return Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(
        begin: begin,
        end: end,
        colors: colors.map(_color).toList(),
      ).createShader(rect);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintTopLeftWaves(canvas, size);
    _paintMiddleRightWaves(canvas, size);
    _paintBottomRightWaves(canvas, size);
  }

  // ==================================================
  // 1. TOP LEFT CORNER
  // ==================================================

  void _paintTopLeftWaves(
      Canvas canvas,
      Size size,
      ) {
    final w = size.width;
    final h = size.height;

    // Outer soft peach wave
    final outerWave = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.53, 0)
      ..cubicTo(
        w * 0.43,
        h * 0.035,
        w * 0.26,
        h * 0.055,
        w * 0.14,
        h * 0.078,
      )
      ..cubicTo(
        w * 0.055,
        h * 0.095,
        0,
        h * 0.125,
        0,
        h * 0.155,
      )
      ..close();

    canvas.drawPath(
      outerWave,
      _gradientPaint(
        Rect.fromLTWH(
          0,
          0,
          w * 0.55,
          h * 0.16,
        ),
        const [
          Color(0xFFFFE0BD),
          Color(0xFFFFF0DE),
        ],
      ),
    );

    // Main orange wave
    final orangeWave = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.40, 0)
      ..cubicTo(
        w * 0.32,
        h * 0.030,
        w * 0.20,
        h * 0.045,
        w * 0.105,
        h * 0.068,
      )
      ..cubicTo(
        w * 0.045,
        h * 0.083,
        0,
        h * 0.110,
        0,
        h * 0.135,
      )
      ..close();

    canvas.drawPath(
      orangeWave,
      _gradientPaint(
        Rect.fromLTWH(
          0,
          0,
          w * 0.42,
          h * 0.14,
        ),
        const [
          Color(0xFFFFA000),
          Color(0xFFF57C00),
          Color(0xFFE65100),
        ],
      ),
    );

    // Thin golden highlight
    final highlight = Path()
      ..moveTo(w * 0.40, 0)
      ..cubicTo(
        w * 0.31,
        h * 0.035,
        w * 0.17,
        h * 0.060,
        w * 0.08,
        h * 0.085,
      )
      ..cubicTo(
        w * 0.035,
        h * 0.100,
        0,
        h * 0.125,
        0,
        h * 0.145,
      )
      ..cubicTo(
        0,
        h * 0.125,
        w * 0.04,
        h * 0.100,
        w * 0.09,
        h * 0.080,
      )
      ..cubicTo(
        w * 0.19,
        h * 0.050,
        w * 0.32,
        h * 0.030,
        w * 0.40,
        0,
      )
      ..close();

    canvas.drawPath(
      highlight,
      _solidPaint(const Color(0xFFFFF0DF)),
    );
  }

  // ==================================================
  // 2. MIDDLE RIGHT CURVED WAVES
  // ==================================================

  void _paintMiddleRightWaves(
      Canvas canvas,
      Size size,
      ) {
    final w = size.width;
    final h = size.height;

    // Outer golden curved section
    final outerWave = Path()
      ..moveTo(w, h * 0.275)
      ..cubicTo(
        w * 0.955,
        h * 0.305,
        w * 0.855,
        h * 0.355,
        w * 0.735,
        h * 0.390,
      )
      ..cubicTo(
        w * 0.835,
        h * 0.375,
        w * 0.930,
        h * 0.375,
        w,
        h * 0.405,
      )
      ..close();

    canvas.drawPath(
      outerWave,
      _gradientPaint(
        Rect.fromLTWH(
          w * 0.72,
          h * 0.27,
          w * 0.28,
          h * 0.15,
        ),
        const [
          Color(0xFFFFE0B2),
          Color(0xFFFFB74D),
          Color(0xFFFF9800),
        ],
      ),
    );

    // Main orange ribbon
    final orangeWave = Path()
      ..moveTo(w, h * 0.300)
      ..cubicTo(
        w * 0.945,
        h * 0.330,
        w * 0.855,
        h * 0.365,
        w * 0.785,
        h * 0.390,
      )
      ..cubicTo(
        w * 0.875,
        h * 0.375,
        w * 0.960,
        h * 0.385,
        w,
        h * 0.405,
      )
      ..close();

    canvas.drawPath(
      orangeWave,
      _gradientPaint(
        Rect.fromLTWH(
          w * 0.78,
          h * 0.30,
          w * 0.22,
          h * 0.11,
        ),
        const [
          Color(0xFFFFA000),
          Color(0xFFF57C00),
          Color(0xFFE65100),
        ],
      ),
    );
  }

  // ==================================================
  // 3. BOTTOM RIGHT WAVES
  // ==================================================

  void _paintBottomRightWaves(
      Canvas canvas,
      Size size,
      ) {
    final w = size.width;
    final h = size.height;

    // Outer light golden wave
    final outerWave = Path()
      ..moveTo(w, h * 0.855)
      ..cubicTo(
        w * 0.955,
        h * 0.895,
        w * 0.865,
        h * 0.940,
        w * 0.755,
        h * 0.970,
      )
      ..cubicTo(
        w * 0.685,
        h * 0.988,
        w * 0.615,
        h * 0.995,
        w * 0.545,
        h,
      )
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(
      outerWave,
      _gradientPaint(
        Rect.fromLTWH(
          w * 0.54,
          h * 0.85,
          w * 0.46,
          h * 0.15,
        ),
        const [
          Color(0xFFFFE6C7),
          Color(0xFFFFCA80),
          Color(0xFFFFA726),
        ],
      ),
    );

    // Main orange wave
    final orangeWave = Path()
      ..moveTo(w, h * 0.890)
      ..cubicTo(
        w * 0.960,
        h * 0.925,
        w * 0.880,
        h * 0.960,
        w * 0.785,
        h * 0.982,
      )
      ..cubicTo(
        w * 0.715,
        h * 0.995,
        w * 0.650,
        h,
        w * 0.600,
        h,
      )
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(
      orangeWave,
      _gradientPaint(
        Rect.fromLTWH(
          w * 0.60,
          h * 0.89,
          w * 0.40,
          h * 0.11,
        ),
        const [
          Color(0xFFFFB74D),
          Color(0xFFFF9800),
          Color(0xFFF57C00),
        ],
      ),
    );
  }

  @override
  bool shouldRepaint(
      covariant _LoginCurvesPainter oldDelegate,
      ) {
    return oldDelegate.isDark != isDark;
  }
}
