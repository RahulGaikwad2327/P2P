import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:p2p_transfer/core/theme/app_theme.dart';
import 'package:p2p_transfer/core/widgets/dot_grid_background.dart';
import 'package:p2p_transfer/core/widgets/hud_components.dart';
import 'package:p2p_transfer/core/widgets/p2p_hero_logo.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      body: DotGridBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Center Hero Logo surrounded by Viewfinder Target Brackets [  ]
                Container(
                  padding: const EdgeInsets.all(28),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Target Brackets ┌ ┐ └ ┘
                      const Positioned.fill(
                        child: CustomPaint(
                          painter: _ViewfinderBracketPainter(),
                        ),
                      ),
                      // Giant P2P Block Logo
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                        child: P2PHeroLogo(width: 420, height: 130),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle Divider
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, color: AppColors.pumpkinOrange),
                      const SizedBox(width: 12),
                      Text(
                        'SECURE CROSS-PLATFORM FILE SHARING',
                        style: GoogleFonts.spaceMono(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(width: 6, height: 6, color: AppColors.pumpkinOrange),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Tagline: FAST • SECURE • E2E ENCRYPTED • RELAY READY
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTagItem('FAST'),
                      _buildDotSeparator(),
                      _buildTagItem('SECURE'),
                      _buildDotSeparator(),
                      _buildTagItem('E2E ENCRYPTED'),
                      _buildDotSeparator(),
                      _buildTagItem('RELAY READY'),
                    ],
                  ),
                ),
                const SizedBox(height: 44),

                // Action Buttons: [ -> SEND FILES ]  [ RECEIVE FILES <- ]
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHUDButton(
                      label: 'SEND FILES',
                      arrowPrefix: '•→ ',
                      arrowSuffix: '',
                      onTap: () => context.go('/send'),
                    ),
                    const SizedBox(width: 24),
                    _buildHUDButton(
                      label: 'RECEIVE FILES',
                      arrowPrefix: '',
                      arrowSuffix: ' ←•',
                      onTap: () => context.go('/receive'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagItem(String label) {
    return Text(
      label,
      style: GoogleFonts.spaceMono(
        color: AppColors.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _buildDotSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        width: 4,
        height: 4,
        decoration: const BoxDecoration(
          color: AppColors.pumpkinOrange,
          shape: BoxShape.rectangle,
        ),
      ),
    );
  }

  Widget _buildHUDButton({
    required String label,
    required String arrowPrefix,
    required String arrowSuffix,
    required VoidCallback onTap,
  }) {
    return OutlineButtonWidget(
      label: '$arrowPrefix$label$arrowSuffix',
      onPressed: onTap,
    );
  }
}

class _ViewfinderBracketPainter extends CustomPainter {
  const _ViewfinderBracketPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const len = 16.0;

    // Top-Left ┌
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, len), paint);

    // Top-Right ┐
    canvas.drawLine(Offset(size.width - len, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);

    // Bottom-Left └
    canvas.drawLine(Offset(0, size.height - len), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);

    // Bottom-Right ┘
    canvas.drawLine(Offset(size.width - len, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - len), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
