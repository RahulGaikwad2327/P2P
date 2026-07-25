import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:p2p_transfer/core/providers/app_providers.dart';
import 'package:p2p_transfer/core/theme/app_theme.dart';
import 'package:p2p_transfer/core/widgets/hud_components.dart';
import 'package:p2p_transfer/models/peer_device.dart';
import 'package:p2p_transfer/services/signaling_service.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(peerDevicesProvider);
    final signalingStatus = ref.watch(signalingStatusProvider);
    final onlineCount = devices.where((d) => d.isOnline).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionTitle(
                title: 'NETWORK NODES // DEVICES',
                subtitle: 'Peers registered with the signaling server',
              ),
              PrimaryButton(
                label: 'REFRESH',
                icon: LucideIcons.refreshCw,
                onPressed: () {
                  final signaling = ref.read(signalingServiceProvider);
                  signaling.sendRaw({'type': 'GET_DEVICES', 'payload': {}});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('DEVICE_UPDATE REQUEST SENT')),
                  );
                },
              ),
            ],
          ),
          const HUDDivider(),

          // Signaling Status Panel
          GlassCard(
            child: Row(
              children: [
                const AnimatedLogo(size: 54),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SIGNALING SERVER // WEBSOCKET',
                        style: GoogleFonts.spaceMono(
                          color: AppColors.pumpkinOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      signalingStatus.when(
                        data: (s) => Text(
                          s == SignalingStatus.connected
                              ? 'Connected — receiving live DEVICE_UPDATE broadcasts'
                              : s == SignalingStatus.connecting || s == SignalingStatus.reconnecting
                                  ? 'Connecting to signaling server...'
                                  : 'Offline — showing cached / mock device list',
                          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
                        ),
                        loading: () => Text('Checking signaling server...',
                            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
                        error: (err, stack) => Text('Server unreachable',
                            style: GoogleFonts.inter(color: AppColors.errorRed, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                StatusChip(
                  label: '$onlineCount / ${devices.length} ONLINE',
                  color: onlineCount > 0 ? AppColors.successGreen : AppColors.textDim,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Device Cards
          if (devices.isEmpty)
            GlassCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const Icon(LucideIcons.wifiOff, size: 48, color: AppColors.textDim),
                      const SizedBox(height: 16),
                      Text(
                        'NO PEERS FOUND',
                        style: GoogleFonts.spaceMono(color: AppColors.textDim, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connect to the signaling server to discover peers',
                        style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...devices.map((device) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _DeviceCard(device: device),
                )),
        ],
      ),
    );
  }
}

class _DeviceCard extends ConsumerWidget {
  final PeerDevice device;
  const _DeviceCard({required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: device.isOnline
                      ? AppColors.pumpkinOrange.withValues(alpha: 0.15)
                      : AppColors.cardDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: device.isOnline
                        ? AppColors.pumpkinOrange
                        : AppColors.cardBorder,
                  ),
                ),
                child: Icon(
                  device.deviceType == 'Mobile'
                      ? LucideIcons.smartphone
                      : LucideIcons.laptop,
                  color: device.isOnline
                      ? AppColors.pumpkinOrange
                      : AppColors.textDim,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          device.name,
                          style: GoogleFonts.inter(
                            color: AppColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: device.isOnline
                                ? AppColors.successGreen
                                : AppColors.textDim,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${device.osName} • ${device.latencyMs}ms latency',
                      style: GoogleFonts.spaceMono(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ConnectionModeBadge(device.connectionMode),
                  const SizedBox(width: 8),
                  if (device.isOnline)
                    OutlineButtonWidget(
                      label: device.trustStatus == TrustStatus.trusted
                          ? 'TRUSTED'
                          : 'TRUST?',
                      icon: device.trustStatus == TrustStatus.trusted
                          ? LucideIcons.shieldCheck
                          : LucideIcons.shield,
                      onPressed: () {
                        ref.read(peerDevicesProvider.notifier).setTrust(
                              device.id,
                              device.trustStatus == TrustStatus.trusted
                                  ? TrustStatus.untrusted
                                  : TrustStatus.trusted,
                            );
                      },
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DeviceExpandedInfo(device: device),
        ],
      ),
    );
  }
}

class _DeviceExpandedInfo extends StatelessWidget {
  final PeerDevice device;
  const _DeviceExpandedInfo({required this.device});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.cardBorder, height: 16),
        // Public key fingerprint
        Row(
          children: [
            const Icon(LucideIcons.key, size: 12, color: AppColors.textDim),
            const SizedBox(width: 6),
            Text(
              'ECDH KEY: ${device.publicKeyFingerprint}',
              style: GoogleFonts.spaceMono(color: AppColors.textDim, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Network info
        Row(
          children: [
            const Icon(LucideIcons.network, size: 12, color: AppColors.textDim),
            const SizedBox(width: 6),
            Text(
              'PUB: ${device.ipAddress}  •  LAN: ${device.localIp.isEmpty ? "N/A" : device.localIp}:${device.port}',
              style: GoogleFonts.spaceMono(color: AppColors.textDim, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Capabilities row
        Wrap(
          spacing: 6,
          children: [
            if (device.capabilities.supportsFolder)
              _CapBadge(label: 'FOLDER XFER', icon: LucideIcons.folder),
            if (device.capabilities.supportsBatch)
              _CapBadge(label: 'BATCH', icon: LucideIcons.layers),
            _CapBadge(
              label: device.formattedMaxFileSize,
              icon: LucideIcons.hardDrive,
            ),
          ],
        ),
      ],
    );
  }
}

class _ConnectionModeBadge extends StatelessWidget {
  final String mode;
  const _ConnectionModeBadge(this.mode);

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (mode) {
      'direct' => ('DIRECT P2P', AppColors.successGreen, LucideIcons.zap),
      'relay' => ('RELAY', AppColors.warningYellow, LucideIcons.arrowLeftRight),
      _ => ('UNKNOWN', AppColors.textDim, LucideIcons.helpCircle),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.spaceMono(color: color, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _CapBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  const _CapBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.pumpkinOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.pumpkinOrange.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppColors.pumpkinOrange),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.spaceMono(
                color: AppColors.pumpkinOrange, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
