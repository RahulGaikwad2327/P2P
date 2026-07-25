import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:p2p_transfer/core/providers/app_providers.dart';
import 'package:p2p_transfer/core/theme/app_theme.dart';
import 'package:p2p_transfer/core/widgets/hud_components.dart';
import 'package:p2p_transfer/services/signaling_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final signalingStatus = ref.watch(signalingStatusProvider);
    final goEngineAvailable = ref.watch(goEngineStatusProvider);
    final session = ref.watch(sessionProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'SYSTEM CONFIGURATION // SETTINGS',
            subtitle: 'Signaling server, Go engine, security, and storage preferences',
          ),
          const HUDDivider(),

          // ── Connection Settings ──────────────────────────────────────
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.server, color: AppColors.pumpkinOrange, size: 15),
                    const SizedBox(width: 8),
                    Text(
                      'SIGNALING SERVER CONFIGURATION',
                      style: GoogleFonts.spaceMono(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    signalingStatus.when(
                      data: (s) => StatusChip(
                        label: s == SignalingStatus.connected ? 'LIVE' : 'OFFLINE',
                        color: s == SignalingStatus.connected
                            ? AppColors.successGreen
                            : AppColors.errorRed,
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (err, stack) => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextSettingEditable(
                  label: 'WEBSOCKET SERVER URL',
                  value: settings.signalingServerUrl,
                  icon: LucideIcons.wifi,
                  hint: 'ws://192.168.1.x:3000',
                  onChanged: (v) =>
                      ref.read(appSettingsProvider.notifier).updateSignalingUrl(v),
                ),
                const SizedBox(height: 12),
                _buildTextSettingEditable(
                  label: 'GO ENGINE PORT (LOCAL)',
                  value: settings.goEnginePort.toString(),
                  icon: LucideIcons.cpu,
                  hint: '9000',
                  onChanged: (v) {
                    final port = int.tryParse(v);
                    if (port != null) {
                      ref.read(appSettingsProvider.notifier).updateGoEnginePort(port);
                    }
                  },
                ),
                const SizedBox(height: 12),
                // Go engine status
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.obsidianBlack,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.cpu,
                          color: AppColors.pumpkinOrange, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: goEngineAvailable.when(
                          data: (available) => Text(
                            available
                                ? 'GO CORE ENGINE: RUNNING ON LOCALHOST:${settings.goEnginePort}'
                                : 'GO CORE ENGINE: NOT DETECTED — SIMULATION MODE',
                            style: GoogleFonts.spaceMono(
                              color: available
                                  ? AppColors.successGreen
                                  : AppColors.warningYellow,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          loading: () => Text('Checking Go engine...',
                              style: GoogleFonts.spaceMono(
                                  color: AppColors.textMuted, fontSize: 11)),
                          error: (err, stack) => Text('ENGINE CHECK FAILED',
                              style: GoogleFonts.spaceMono(
                                  color: AppColors.errorRed, fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Security Settings ────────────────────────────────────────
          GlassCard(
            child: Column(
              children: [
                _buildSwitchTile(
                  title: 'FORCE AES-256-GCM ENCRYPTION',
                  subtitle:
                      'Go engine uses AES-256-GCM for all chunk data. Reject unencrypted peers.',
                  value: settings.encryptionEnabled,
                  onChanged: (val) =>
                      ref.read(appSettingsProvider.notifier).updateEncryption(val),
                ),
                const HUDDivider(),
                _buildSwitchTile(
                  title: 'ALLOW RELAY FALLBACK',
                  subtitle:
                      'If direct NAT traversal fails, route via signaling server relay path',
                  value: settings.useRelay,
                  onChanged: (val) =>
                      ref.read(appSettingsProvider.notifier).updateUseRelay(val),
                ),
                const HUDDivider(),
                _buildSwitchTile(
                  title: 'AUTO-ACCEPT INCOMING TRANSFERS',
                  subtitle: 'Automatically receive payloads from verified trusted peers',
                  value: settings.autoAccept,
                  onChanged: (val) =>
                      ref.read(appSettingsProvider.notifier).updateAutoAccept(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Session / JWT Info ────────────────────────────────────────
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.fingerprint,
                        color: AppColors.pumpkinOrange, size: 15),
                    const SizedBox(width: 8),
                    Text(
                      'SESSION IDENTITY',
                      style: GoogleFonts.spaceMono(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildInfoRow(
                  'DEVICE ID',
                  session?.deviceId ?? '-- not registered --',
                  LucideIcons.hash,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'SESSION ID',
                  session?.sessionId ?? '-- no active session --',
                  LucideIcons.keyRound,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'JWT TOKEN',
                  session != null
                      ? '${session.token.substring(0, session.token.length.clamp(0, 20))}...'
                      : '-- not authenticated --',
                  LucideIcons.lock,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Transfer Protocol ─────────────────────────────────────────
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.activity,
                        color: AppColors.pumpkinOrange, size: 15),
                    const SizedBox(width: 8),
                    Text(
                      'TRANSFER PROTOCOL (GO ENGINE)',
                      style: GoogleFonts.spaceMono(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildInfoRow('CHUNK SIZE', '${settings.chunkSize ~/ 1024} KB', LucideIcons.layers),
                const SizedBox(height: 8),
                _buildInfoRow('WIRE PROTOCOL', 'Binary v1 • SYN/ACK/DATA/FIN', LucideIcons.binary),
                const SizedBox(height: 8),
                _buildInfoRow('KEY EXCHANGE', 'ECDH-P256 via Go crypto/ecdh', LucideIcons.key),
                const SizedBox(height: 8),
                _buildInfoRow('TRANSPORT', 'TLS 1.3 + AES-256-GCM', LucideIcons.shield),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Actions ────────────────────────────────────────────────────
          Row(
            children: [
              OutlineButtonWidget(
                label: 'ROTATE KEYS',
                icon: LucideIcons.rotateCcw,
                onPressed: () async {
                  await ref.read(encryptionServiceProvider).rotateKeys();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ECDH KEY PAIR ROTATED')),
                    );
                  }
                },
              ),
              const SizedBox(width: 12),
              OutlineButtonWidget(
                label: 'RECONNECT SIGNALING',
                icon: LucideIcons.plugZap,
                onPressed: () {
                  ref.read(sessionProvider.notifier).connectToSignalingServer();
                },
              ),
              const SizedBox(width: 12),
              OutlineButtonWidget(
                label: 'CLEAR SESSION',
                icon: LucideIcons.trash2,
                onPressed: () {
                  ref.read(sessionProvider.notifier).clearSession();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('SESSION CLEARED')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceMono(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: AppColors.pumpkinOrange,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextSettingEditable({
    required String label,
    required String value,
    required IconData icon,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.obsidianBlack,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.pumpkinOrange, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        GoogleFonts.spaceMono(color: AppColors.textMuted, fontSize: 10)),
                TextFormField(
                  initialValue: value,
                  style: GoogleFonts.spaceMono(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: hint,
                    hintStyle: GoogleFonts.spaceMono(
                        color: AppColors.textDim, fontSize: 13),
                    border: InputBorder.none,
                  ),
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textDim, size: 13),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.spaceMono(color: AppColors.textMuted, fontSize: 10),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.spaceMono(
                color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
