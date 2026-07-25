import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:p2p_transfer/core/theme/app_theme.dart';
import 'package:p2p_transfer/core/widgets/hud_components.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'SYSTEM INFO // ABOUT',
            subtitle: 'Architecture details, design system specifications, and open-source license',
          ),
          const HUDDivider(),

          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AnimatedLogo(size: 40),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SECURE CROSS-PLATFORM FILE SHARING',
                          style: GoogleFonts.spaceMono(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'VERSION 2.0.0 // DECENTRALIZED ARCH',
                          style: GoogleFonts.spaceMono(
                            color: AppColors.pumpkinOrange,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const HUDDivider(),

                Text(
                  'DESIGN SYSTEM & AESTHETIC',
                  style: GoogleFonts.spaceMono(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Architecture: Flutter Client → Node.js WebSocket Signaling Server → Go Core Engine (P2P/Relay). Files never transit the signaling server. All chunk data is AES-256-GCM encrypted by the Go engine with ECDH-P256 key exchange. Credentials stored via flutter_secure_storage.',
                  style: GoogleFonts.inter(
                    color: AppColors.white,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'CORE TECH STACK:',
                  style: GoogleFonts.spaceMono(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    // Flutter Stack
                    StatusChip(label: 'FLUTTER 3.16+', color: AppColors.pumpkinOrange),
                    StatusChip(label: 'RIVERPOD 2.5', color: AppColors.white),
                    StatusChip(label: 'GOROUTER 14', color: AppColors.white),
                    StatusChip(label: 'WEB_SOCKET_CHANNEL', color: AppColors.white),
                    StatusChip(label: 'SECURE_STORAGE', color: AppColors.successGreen),
                    StatusChip(label: 'CONNECTIVITY_PLUS', color: AppColors.white),
                    // Signaling Server
                    StatusChip(label: 'NODE.JS 20', color: AppColors.pumpkinOrange),
                    StatusChip(label: 'WS + JWT + HELMET', color: AppColors.white),
                    StatusChip(label: 'TYPESCRIPT 5', color: AppColors.white),
                    // Go Engine
                    StatusChip(label: 'GO 1.21+', color: AppColors.pumpkinOrange),
                    StatusChip(label: 'AES-256-GCM', color: AppColors.successGreen),
                    StatusChip(label: 'TLS 1.3', color: AppColors.successGreen),
                    StatusChip(label: 'ECDH-P256', color: AppColors.successGreen),
                    // UI
                    StatusChip(label: 'FL_CHART', color: AppColors.white),
                    StatusChip(label: 'QR_FLUTTER', color: AppColors.white),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    OutlineButtonWidget(
                      label: 'GITHUB REPOSITORY',
                      icon: LucideIcons.github,
                      onPressed: () {},
                    ),
                    const SizedBox(width: 12),
                    OutlineButtonWidget(
                      label: 'MIT LICENSE',
                      icon: LucideIcons.fileText,
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
