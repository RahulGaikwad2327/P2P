import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:p2p_transfer/core/theme/app_theme.dart';
import 'package:p2p_transfer/core/widgets/hud_components.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      body: Center(
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.alertTriangle, color: AppColors.pumpkinOrange, size: 48),
              const SizedBox(height: 16),
              Text(
                '404 // ROUTE NOT FOUND',
                style: GoogleFonts.spaceMono(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The requested matrix path does not exist in router table.',
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'RETURN TO HOME',
                icon: LucideIcons.home,
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
