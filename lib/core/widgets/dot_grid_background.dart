import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:p2p_transfer/core/theme/app_theme.dart';

class DotGridBackground extends StatefulWidget {
  final Widget child;
  final bool showHUDOverlay;

  const DotGridBackground({
    super.key,
    required this.child,
    this.showHUDOverlay = true,
  });

  @override
  State<DotGridBackground> createState() => _DotGridBackgroundState();
}

class _DotGridBackgroundState extends State<DotGridBackground> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Offset _mousePosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        setState(() {
          _mousePosition = event.localPosition;
        });
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          return CustomPaint(
            painter: _DotGridPainter(
              pulseValue: _pulseController.value,
              mousePosition: _mousePosition,
              showHUD: widget.showHUDOverlay,
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final double pulseValue;
  final Offset mousePosition;
  final bool showHUD;

  _DotGridPainter({
    required this.pulseValue,
    required this.mousePosition,
    required this.showHUD,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = AppColors.obsidianBlack;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    const double spacing = 32.0;
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final orangeDotPaint = Paint()
      ..color = AppColors.pumpkinOrange.withValues(alpha: 0.25 + (pulseValue * 0.25))
      ..style = PaintingStyle.fill;

    // Draw Matrix Grid Dots
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        final distToMouse = (Offset(x, y) - mousePosition).distance;
        final isNearMouse = distToMouse < 140;

        if ((x.toInt() / spacing).floor() % 6 == 0 && (y.toInt() / spacing).floor() % 4 == 0) {
          canvas.drawCircle(Offset(x, y), 1.6, orangeDotPaint);
        } else {
          final radius = isNearMouse ? 1.8 : 1.0;
          final currentPaint = isNearMouse
              ? (Paint()..color = AppColors.pumpkinOrange.withValues(alpha: 0.6))
              : dotPaint;
          canvas.drawCircle(Offset(x, y), radius, currentPaint);
        }
      }
    }

    if (showHUD) {
      final linePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      final orangeLinePaint = Paint()
        ..color = AppColors.pumpkinOrange.withValues(alpha: 0.6)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      const margin = 28.0;
      const bracketLen = 20.0;

      // Outer Corner Bracket Lines (Matching Reference Image)
      // Top-Left
      canvas.drawLine(const Offset(margin, margin + bracketLen), const Offset(margin, margin), linePaint);
      canvas.drawLine(const Offset(margin, margin), const Offset(margin + bracketLen, margin), linePaint);
      canvas.drawLine(const Offset(margin + 4, margin + 4), const Offset(margin + 12, margin + 4), orangeLinePaint);

      // Top-Right
      canvas.drawLine(Offset(size.width - margin - bracketLen, margin), Offset(size.width - margin, margin), linePaint);
      canvas.drawLine(Offset(size.width - margin, margin), Offset(size.width - margin, margin + bracketLen), linePaint);

      // Bottom-Left
      canvas.drawLine(Offset(margin, size.height - margin - bracketLen), Offset(margin, size.height - margin), linePaint);
      canvas.drawLine(Offset(margin, size.height - margin), Offset(margin + bracketLen, size.height - margin), linePaint);

      // Bottom-Right
      canvas.drawLine(Offset(size.width - margin - bracketLen, size.height - margin), Offset(size.width - margin, size.height - margin), linePaint);
      canvas.drawLine(Offset(size.width - margin, size.height - margin), Offset(size.width - margin, size.height - margin - bracketLen), linePaint);

      // Draw Top HUD Header Text
      _drawText(canvas, '• P2P TRANSFER |', const Offset(margin + 28, margin - 6), color: AppColors.pumpkinOrange);
      _drawText(canvas, 'DECENTRALIZED   •   END-TO-END   •   ENCRYPTED', Offset(size.width / 2 - 140, margin - 6), color: AppColors.textMuted);
      _drawText(canvas, 'OPEN SOURCE +', Offset(size.width - margin - 120, margin - 6), color: AppColors.pumpkinOrange);

      // Draw Side Lat/Long Coordinates
      _drawRotatedText(canvas, '29° 42\' 12.8" N', Offset(margin - 14, size.height / 2 + 50), -1.5708);
      _drawRotatedText(canvas, '90° 19\' 40.2" E', Offset(size.width - margin + 14, size.height / 2 - 50), 1.5708);

      // Draw Bottom HUD Status Bar (Matching Reference Image)
      final bottomY = size.height - margin - 4;
      final sectionW = size.width / 5;

      // Horizontal separator line above bottom status bar
      canvas.drawLine(Offset(margin, bottomY - 24), Offset(size.width - margin, bottomY - 24), linePaint);

      // Status Item 1: Status
      _drawText(canvas, 'STATUS', Offset(margin + 30, bottomY - 20), fontSize: 9, color: AppColors.textMuted);
      _drawText(canvas, 'READY TO CONNECT', Offset(margin + 30, bottomY - 8), fontSize: 10, color: AppColors.pumpkinOrange);

      // Status Item 2: Peers
      _drawText(canvas, 'PEERS', Offset(margin + sectionW + 20, bottomY - 20), fontSize: 9, color: AppColors.textMuted);
      _drawText(canvas, '0 CONNECTED', Offset(margin + sectionW + 20, bottomY - 8), fontSize: 10, color: AppColors.pumpkinOrange);

      // Center Viewfinder Target Graphic
      _drawCenterViewfinder(canvas, Offset(size.width / 2, bottomY - 10));

      // Status Item 4: Encryption
      _drawText(canvas, 'ENCRYPTION', Offset(size.width - margin - sectionW * 1.8, bottomY - 20), fontSize: 9, color: AppColors.textMuted);
      _drawText(canvas, 'END-TO-END', Offset(size.width - margin - sectionW * 1.8, bottomY - 8), fontSize: 10, color: AppColors.pumpkinOrange);

      // Status Item 5: Version
      _drawText(canvas, 'VERSION', Offset(size.width - margin - sectionW * 0.7, bottomY - 20), fontSize: 9, color: AppColors.textMuted);
      _drawText(canvas, '1.0.0', Offset(size.width - margin - sectionW * 0.7, bottomY - 8), fontSize: 10, color: AppColors.pumpkinOrange);

      // 4-Dot LED Grids on bottom corners
      _drawDotLEDArray(canvas, Offset(margin + 8, bottomY - 14));
      _drawDotLEDArray(canvas, Offset(size.width - margin - 20, bottomY - 14));
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, {Color color = Colors.white, double fontSize = 10}) {
    final textStyle = GoogleFonts.spaceMono(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  void _drawRotatedText(Canvas canvas, String text, Offset position, double angle) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle);
    final textStyle = GoogleFonts.spaceMono(
      color: AppColors.textDim,
      fontSize: 9,
      letterSpacing: 1.5,
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  void _drawCenterViewfinder(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = AppColors.pumpkinOrange
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const size = 10.0;
    // Square target corners [ ]
    canvas.drawLine(Offset(center.dx - size, center.dy - size), Offset(center.dx - size + 4, center.dy - size), paint);
    canvas.drawLine(Offset(center.dx - size, center.dy - size), Offset(center.dx - size, center.dy - size + 4), paint);

    canvas.drawLine(Offset(center.dx + size, center.dy - size), Offset(center.dx + size - 4, center.dy - size), paint);
    canvas.drawLine(Offset(center.dx + size, center.dy - size), Offset(center.dx + size, center.dy - size + 4), paint);

    canvas.drawLine(Offset(center.dx - size, center.dy + size), Offset(center.dx - size + 4, center.dy + size), paint);
    canvas.drawLine(Offset(center.dx - size, center.dy + size), Offset(center.dx - size, center.dy + size - 4), paint);

    canvas.drawLine(Offset(center.dx + size, center.dy + size), Offset(center.dx + size - 4, center.dy + size), paint);
    canvas.drawLine(Offset(center.dx + size, center.dy + size), Offset(center.dx + size, center.dy + size - 4), paint);

    // Center crosshair dot
    canvas.drawCircle(center, 1.5, Paint()..color = AppColors.pumpkinOrange);
  }

  void _drawDotLEDArray(Canvas canvas, Offset start) {
    final orangePaint = Paint()..color = AppColors.pumpkinOrange;
    canvas.drawRect(Rect.fromLTWH(start.dx, start.dy, 3, 3), orangePaint);
    canvas.drawRect(Rect.fromLTWH(start.dx + 5, start.dy, 3, 3), orangePaint);
    canvas.drawRect(Rect.fromLTWH(start.dx, start.dy + 5, 3, 3), orangePaint);
    canvas.drawRect(Rect.fromLTWH(start.dx + 5, start.dy + 5, 3, 3), orangePaint);
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue || oldDelegate.mousePosition != mousePosition;
  }
}
