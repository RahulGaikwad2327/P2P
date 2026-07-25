import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:p2p_transfer/core/providers/app_providers.dart';
import 'package:p2p_transfer/core/theme/app_theme.dart';
import 'package:p2p_transfer/core/widgets/hud_components.dart';

class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  late String _pairCode;
  bool _hasIncomingRequest = false;
  String _localIp = '0.0.0.0';

  @override
  void initState() {
    super.initState();
    _pairCode = ref.read(signalingServiceProvider).generatePairCode();
    _resolveLocalIp();
    _listenForIncomingRequests();
  }

  Future<void> _resolveLocalIp() async {
    if (kIsWeb) {
      setState(() => _localIp = '127.0.0.1');
      return;
    }
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            setState(() => _localIp = addr.address);
            return;
          }
        }
      }
    } catch (_) {
      setState(() => _localIp = '127.0.0.1');
    }
  }

  void _listenForIncomingRequests() {
    // Show incoming request panel for demonstration / web testing
    setState(() => _hasIncomingRequest = true);
  }

  void _acceptIncomingRequest() {
    final transferId = 'tx_${DateTime.now().millisecondsSinceEpoch}';

    ref.read(activeTransferProvider.notifier).startReceiving(
          transferId: transferId,
          peerDeviceId: 'node_alpha_9',
          peerDeviceName: 'CyberBook Pro 16',
          fileName: 'arch_linux_custom_kernel.tar.xz',
          fileSize: 245000000,
          fileHash: 'e3b0c44298fc1c149afbf4c8996fb924',
          mimeType: 'application/x-xz',
          chunkSize: 65536,
        );

    setState(() => _hasIncomingRequest = false);
    context.go('/transfer');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'RECEIVE FILES // RADAR LISTENER',
            subtitle: 'Waiting for incoming direct connection requests on subnet',
          ),
          const HUDDivider(),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: QR & Pair Code
              Expanded(
                flex: 3,
                child: GlassCard(
                  child: Column(
                    children: [
                      StatusChip(
                        label: 'SOCKET LISTENING • PORT 9000 • $_localIp',
                        color: AppColors.successGreen,
                        icon: LucideIcons.radio,
                      ),
                      const SizedBox(height: 24),

                      // QR Code Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data: 'p2p://pair?code=$_pairCode&ip=$_localIp&port=9000',
                          version: QrVersions.auto,
                          size: 180.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'OR ENTER DEVICE PAIRING CODE',
                        style: GoogleFonts.spaceMono(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Pair Code Display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.obsidianBlack,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.pumpkinOrange),
                        ),
                        child: Text(
                          '${_pairCode.substring(0, 3)} ${_pairCode.substring(3)}',
                          style: GoogleFonts.spaceMono(
                            color: AppColors.pumpkinOrange,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 6.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'Code regenerates automatically every 10 minutes',
                        style: GoogleFonts.inter(
                          color: AppColors.textDim,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),

              // Right Column: Pending Incoming Requests
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INCOMING CONNECTION REQUESTS',
                      style: GoogleFonts.spaceMono(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_hasIncomingRequest)
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.pumpkinOrange.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(LucideIcons.download, color: AppColors.pumpkinOrange, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'CyberBook Pro 16',
                                        style: GoogleFonts.inter(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'IP: 192.168.1.104',
                                        style: GoogleFonts.spaceMono(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const HUDDivider(),
                            Text(
                              'PAYLOAD INFORMATION:',
                              style: GoogleFonts.spaceMono(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'arch_linux_custom_kernel.tar.xz',
                              style: GoogleFonts.inter(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Size: 245 MB • Format: Archive',
                              style: GoogleFonts.spaceMono(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: PrimaryButton(
                                    label: 'ACCEPT',
                                    icon: LucideIcons.check,
                                    onPressed: _acceptIncomingRequest,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlineButtonWidget(
                                    label: 'REJECT',
                                    icon: LucideIcons.x,
                                    onPressed: () {
                                      setState(() => _hasIncomingRequest = false);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(LucideIcons.checkCircle, color: AppColors.textDim, size: 32),
                                const SizedBox(height: 10),
                                Text(
                                  'No pending requests.',
                                  style: GoogleFonts.spaceMono(color: AppColors.textDim, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
