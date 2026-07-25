import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:p2p_transfer/core/providers/app_providers.dart';
import 'package:p2p_transfer/core/theme/app_theme.dart';
import 'package:p2p_transfer/core/widgets/hud_components.dart';
import 'package:p2p_transfer/models/transfer_session.dart';
import 'package:p2p_transfer/services/signaling_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peers = ref.watch(peerDevicesProvider);
    final history = ref.watch(transferHistoryProvider);
    final onlineCount = peers.where((p) => p.isOnline).length;
    final signalingStatus = ref.watch(signalingStatusProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Welcome Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NODE // MATRIX_DASHBOARD',
                    style: GoogleFonts.spaceMono(
                      color: AppColors.pumpkinOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Secure P2P Transfer Hub',
                    style: GoogleFonts.spaceMono(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _SignalingStatusChip(signalingStatus),
                  const SizedBox(height: 8),
                  OutlineButtonWidget(
                    label: 'SEARCH DEVS',
                    icon: LucideIcons.search,
                    onPressed: () => context.go('/devices'),
                  ),
                ],
              ),
            ],
          ),
          const HUDDivider(),

          // Quick Action Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 700;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isSmall ? 1 : 3,
                childAspectRatio: isSmall ? 2.5 : 1.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildQuickActionCard(
                    title: 'SEND FILES',
                    subtitle: 'Drop files or select from directory to transfer to peer',
                    icon: LucideIcons.uploadCloud,
                    color: AppColors.pumpkinOrange,
                    onTap: () => context.go('/send'),
                  ),
                  _buildQuickActionCard(
                    title: 'RECEIVE FILES',
                    subtitle: 'Display QR code or 6-digit pair code for incoming payload',
                    icon: LucideIcons.downloadCloud,
                    color: AppColors.successGreen,
                    onTap: () => context.go('/receive'),
                  ),
                  _buildQuickActionCard(
                    title: 'NEARBY DEVICES',
                    subtitle: '$onlineCount Online Peer Node(s) detected on subnet',
                    icon: LucideIcons.hardDrive,
                    color: AppColors.white,
                    onTap: () => context.go('/devices'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // Network & Storage Meter Row
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  child: Row(
                    children: [
                      const ProgressRingWidget(
                        progress: 0.42,
                        size: 90,
                        label: 'STORAGE',
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LOCAL STORAGE USAGE',
                              style: GoogleFonts.spaceMono(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '214.5 GB / 512 GB',
                              style: GoogleFonts.spaceMono(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Default directory: ~/Downloads/P2P',
                              style: GoogleFonts.inter(
                                color: AppColors.textDim,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GlassCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.pumpkinOrange.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.pumpkinOrange),
                        ),
                        child: const Icon(LucideIcons.activity, color: AppColors.pumpkinOrange, size: 32),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PEAK BANDWIDTH SPEED',
                              style: GoogleFonts.spaceMono(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '64.2 MB/s',
                              style: GoogleFonts.spaceMono(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Direct TCP Socket • Zero Compression Loss',
                              style: GoogleFonts.inter(
                                color: AppColors.textDim,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Recent Activity Section
          SectionTitle(
            title: 'RECENT TRANSFERS',
            subtitle: 'Latest incoming and outgoing peer files',
            trailing: TextButton(
              onPressed: () => context.go('/history'),
              child: Text(
                'VIEW ALL HISTORY >',
                style: GoogleFonts.spaceMono(
                  color: AppColors.pumpkinOrange,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          if (history.isEmpty)
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No recent file transfers.',
                    style: GoogleFonts.spaceMono(color: AppColors.textMuted),
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length > 3 ? 3 : history.length,
              itemBuilder: (context, index) {
                final session = history[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: GlassCard(
                    child: Row(
                      children: [
                        Icon(
                          session.direction == TransferDirection.sending
                              ? LucideIcons.upload
                              : LucideIcons.download,
                          color: session.direction == TransferDirection.sending
                              ? AppColors.pumpkinOrange
                              : AppColors.successGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.files.first.name,
                                style: GoogleFonts.inter(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${session.peerDeviceName} • ${session.files.first.formattedSize}',
                                style: GoogleFonts.spaceMono(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusChip(
                          label: session.state.name,
                          color: AppColors.successGreen,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Icon(LucideIcons.arrowUpRight, color: color.withValues(alpha: 0.6), size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceMono(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignalingStatusChip extends StatelessWidget {
  final AsyncValue<SignalingStatus> statusAsync;
  const _SignalingStatusChip(this.statusAsync);

  @override
  Widget build(BuildContext context) {
    final status = statusAsync.valueOrNull ?? SignalingStatus.disconnected;

    final (label, color, icon) = switch (status) {
      SignalingStatus.connected => (
          'SIGNALING LIVE',
          AppColors.successGreen,
          LucideIcons.wifi
        ),
      SignalingStatus.connecting || SignalingStatus.reconnecting => (
          'CONNECTING...',
          AppColors.warningYellow,
          LucideIcons.loader
        ),
      SignalingStatus.error => (
          'SERVER ERROR',
          AppColors.errorRed,
          LucideIcons.wifiOff
        ),
      _ => ('MOCK MODE', AppColors.textDim, LucideIcons.wifiOff),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.spaceMono(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
