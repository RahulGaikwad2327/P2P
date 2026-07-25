import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:p2p_transfer/core/theme/app_theme.dart';

class P2PHeroLogo extends StatelessWidget {
  final double width;
  final double height;

  const P2PHeroLogo({
    super.key,
    this.width = 440.0,
    this.height = 140.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      child: Text(
        'P2P',
        style: GoogleFonts.orbitron(
          fontSize: 92,
          fontWeight: FontWeight.w900,
          letterSpacing: 14.0,
          color: AppColors.pumpkinOrange,
        ),
      ),
    );
  }
}
