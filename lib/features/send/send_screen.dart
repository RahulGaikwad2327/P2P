import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:p2p_transfer/core/providers/app_providers.dart';
import 'package:p2p_transfer/core/theme/app_theme.dart';
import 'package:p2p_transfer/core/widgets/hud_components.dart';
import 'package:p2p_transfer/models/transfer_session.dart';

class SendScreen extends ConsumerStatefulWidget {
  const SendScreen({super.key});

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  bool _isHoveringDropZone = false;
  List<String> _realFilePaths = [];

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: kIsWeb,
      );

      if (result != null && result.files.isNotEmpty) {
        final currentFiles = ref.read(selectedFilesProvider);
        final newFiles = <TransferFileItem>[];
        final newPaths = <String>[];

        for (final file in result.files) {
          final fileId = 'file_${DateTime.now().millisecondsSinceEpoch}_${file.name.hashCode}';
          final filePath = kIsWeb ? null : file.path;

          newFiles.add(TransferFileItem(
            id: fileId,
            name: file.name,
            sizeBytes: file.size,
            mimeType: _getMimeType(file.name),
            localPath: filePath,
          ));
          if (filePath != null) {
            newPaths.add(filePath);
          }
        }

        _realFilePaths = [..._realFilePaths, ...newPaths];
        ref.read(selectedFilesProvider.notifier).state = [...currentFiles, ...newFiles];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('FILE PICKER ERROR: $e')),
        );
      }
    }
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'zip':
        return 'application/zip';
      case 'json':
        return 'application/json';
      case 'txt':
        return 'text/plain';
      case 'doc':
      case 'docx':
        return 'application/msword';
      default:
        return 'application/octet-stream';
    }
  }

  void _removeFile(String id) {
    final currentFiles = ref.read(selectedFilesProvider);
    ref.read(selectedFilesProvider.notifier).state = currentFiles.where((f) => f.id != id).toList();
  }

  void _initiateTransfer() {
    final selectedFiles = ref.read(selectedFilesProvider);
    final peers = ref.read(peerDevicesProvider);
    final selectedPeer = ref.read(selectedPeerProvider) ??
        (peers.isNotEmpty ? peers.firstWhere((p) => p.isOnline, orElse: () => peers.first) : null);

    if (selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PLEASE SELECT AT LEAST ONE FILE TO SEND')),
      );
      return;
    }

    if (selectedPeer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NO TARGET PEER DEVICE SELECTED')),
      );
      return;
    }

    final transferId = 'tx_${DateTime.now().millisecondsSinceEpoch}';

    // Send SEND_OFFER to target device via signaling server
    ref.read(signalingServiceProvider).sendOffer(
      toDeviceId: selectedPeer.id,
      transferId: transferId,
      fileName: selectedFiles.first.name,
      fileSize: selectedFiles.first.sizeBytes,
      fileHash: selectedFiles.first.fileHash,
      mimeType: selectedFiles.first.mimeType,
      chunkSize: 65536,
    );

    // Start transfer session via Go engine / simulation bridge
    ref.read(activeTransferProvider.notifier).startTransfer(
      targetDevice: selectedPeer,
      files: selectedFiles,
      transferId: transferId,
    );

    context.go('/transfer');
  }

  @override
  Widget build(BuildContext context) {
    final selectedFiles = ref.watch(selectedFilesProvider);
    final peers = ref.watch(peerDevicesProvider);
    final selectedPeer = ref.watch(selectedPeerProvider) ?? (peers.isNotEmpty ? peers.first : null);

    final totalSizeBytes = selectedFiles.fold<int>(0, (sum, f) => sum + f.sizeBytes);
    final formattedTotalSize = totalSizeBytes < 1024 * 1024
        ? '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB'
        : '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'SEND FILES // STAGING ZONE',
            subtitle: 'Select payloads and choose destination peer on local network',
          ),
          const HUDDivider(),

          // Drag and Drop Zone
          MouseRegion(
            onEnter: (_) => setState(() => _isHoveringDropZone = true),
            onExit: (_) => setState(() => _isHoveringDropZone = false),
            child: GestureDetector(
              onTap: _pickFiles,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 180,
                decoration: BoxDecoration(
                  color: _isHoveringDropZone ? AppColors.pumpkinOrange.withValues(alpha: 0.08) : AppColors.cardDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isHoveringDropZone ? AppColors.pumpkinOrange : AppColors.cardBorder,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.uploadCloud,
                        size: 42,
                        color: _isHoveringDropZone ? AppColors.pumpkinOrange : AppColors.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'DRAG & DROP FILES HERE OR CLICK TO BROWSE',
                        style: GoogleFonts.spaceMono(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Supports any file format • Up to 100 GB per transfer session',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Selected Files List & Destination Peer Layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected Files Section
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SELECTED PAYLOADS (${selectedFiles.length})',
                          style: GoogleFonts.spaceMono(
                            color: AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (selectedFiles.isNotEmpty)
                          Text(
                            'TOTAL SIZE: $formattedTotalSize',
                            style: GoogleFonts.spaceMono(
                              color: AppColors.pumpkinOrange,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (selectedFiles.isEmpty)
                      GlassCard(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              'No files selected yet. Click the zone above to add files.',
                              style: GoogleFonts.spaceMono(color: AppColors.textDim, fontSize: 12),
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: selectedFiles.length,
                        itemBuilder: (context, index) {
                          final file = selectedFiles[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: GlassCard(
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.file, color: AppColors.pumpkinOrange, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          file.name,
                                          style: GoogleFonts.inter(
                                            color: AppColors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          '${file.formattedSize} • ${file.mimeType}',
                                          style: GoogleFonts.spaceMono(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash2, color: AppColors.errorRed, size: 16),
                                    onPressed: () => _removeFile(file.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Peer Target Selection Section
              Expanded(
                flex: 2,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DESTINATION PEER NODE',
                        style: GoogleFonts.spaceMono(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const HUDDivider(),
                      if (peers.isEmpty)
                        Text(
                          'No peer devices found.',
                          style: GoogleFonts.spaceMono(color: AppColors.textDim),
                        )
                      else
                        Column(
                          children: peers.map((device) {
                            final isSelected = selectedPeer?.id == device.id;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: InkWell(
                                onTap: () {
                                  ref.read(selectedPeerProvider.notifier).state = device;
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.pumpkinOrange.withValues(alpha: 0.15) : AppColors.obsidianBlack,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSelected ? AppColors.pumpkinOrange : AppColors.cardBorder,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                                        color: isSelected ? AppColors.pumpkinOrange : AppColors.textMuted,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              device.name,
                                              style: GoogleFonts.inter(
                                                color: AppColors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              device.ipAddress,
                                              style: GoogleFonts.spaceMono(
                                                color: AppColors.textMuted,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),

                      // Encryption Status Badge
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.obsidianBlack,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.lock, color: AppColors.successGreen, size: 14),
                            const SizedBox(width: 8),
                            Text(
                              'AES-256-GCM ENCRYPTED',
                              style: GoogleFonts.spaceMono(
                                color: AppColors.successGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label: 'INITIATE TRANSFER',
                          icon: LucideIcons.send,
                          onPressed: selectedFiles.isNotEmpty ? _initiateTransfer : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
