import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:p2p_transfer/core/theme/app_theme.dart';
import 'package:p2p_transfer/core/widgets/hud_components.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'NODE IDENTITY // PROFILE',
            subtitle: 'Local device cryptographic identity and bandwidth telemetry',
          ),
          const HUDDivider(),

          GlassCard(
            child: Row(
              children: [
                const AnimatedLogo(size: 64),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'CYBER_WORKSTATION_PRO',
                            style: GoogleFonts.spaceMono(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const StatusChip(
                            label: 'MASTER NODE',
                            color: AppColors.pumpkinOrange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: node_local_master_0x89A12F',
                        style: GoogleFonts.spaceMono(color: AppColors.textMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'FINGERPRINT: SHA256:4a8b9c...f1e0',
                        style: GoogleFonts.spaceMono(color: AppColors.textDim, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Telemetry Stats Row
          Row(
            children: [
              _buildStatBox('TOTAL TRANSFERS', '231', LucideIcons.activity),
              const SizedBox(width: 16),
              _buildStatBox('DATA SENT', '854.2 GB', LucideIcons.arrowUpRight),
              const SizedBox(width: 16),
              _buildStatBox('DATA RECEIVED', '342.1 GB', LucideIcons.arrowDownLeft),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon) {
    return Expanded(
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.pumpkinOrange, size: 22),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.spaceMono(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.spaceMono(color: AppColors.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
