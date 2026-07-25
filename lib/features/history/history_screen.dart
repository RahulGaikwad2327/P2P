import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:p2p_transfer/core/providers/app_providers.dart';
import 'package:p2p_transfer/core/theme/app_theme.dart';
import 'package:p2p_transfer/core/widgets/hud_components.dart';
import 'package:p2p_transfer/core/utils/file_download_helper.dart';
import 'package:p2p_transfer/models/transfer_session.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(transferHistoryProvider);

    final filtered = history.where((session) {
      final matchesSearch = _searchQuery.isEmpty ||
          session.peerDeviceName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          session.files.any((f) => f.name.toLowerCase().contains(_searchQuery.toLowerCase()));

      if (!matchesSearch) return false;

      if (_selectedFilter == 'SENT') return session.direction == TransferDirection.sending;
      if (_selectedFilter == 'RECEIVED') return session.direction == TransferDirection.receiving;
      if (_selectedFilter == 'FAILED') return session.state == TransferState.failed || session.state == TransferState.cancelled;

      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionTitle(
                title: 'TRANSFER LOGS // HISTORY',
                subtitle: 'Audited log of all peer file transactions',
              ),
              OutlineButtonWidget(
                label: 'CLEAR HISTORY',
                icon: LucideIcons.trash,
                onPressed: () {
                  ref.read(transferHistoryProvider.notifier).clearHistory();
                },
              ),
            ],
          ),
          const HUDDivider(),

          // Search and Filter Bar
          Row(
            children: [
              Expanded(
                child: SearchBarWidget(
                  hintText: 'Search transfers by file or node name...',
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 16),

              Row(
                children: ['ALL', 'SENT', 'RECEIVED', 'FAILED'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: ChoiceChip(
                      label: Text(
                        filter,
                        style: GoogleFonts.spaceMono(
                          color: isSelected ? AppColors.obsidianBlack : AppColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.pumpkinOrange,
                      backgroundColor: AppColors.cardDark,
                      onSelected: (sel) => setState(() => _selectedFilter = filter),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (filtered.isEmpty)
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'No transfer records match query filters.',
                    style: GoogleFonts.spaceMono(color: AppColors.textMuted),
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final session = filtered[index];
                final isSending = session.direction == TransferDirection.sending;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GlassCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSending ? AppColors.pumpkinOrange.withValues(alpha: 0.12) : AppColors.successGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isSending ? LucideIcons.upload : LucideIcons.download,
                            color: isSending ? AppColors.pumpkinOrange : AppColors.successGreen,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    session.files.first.name,
                                    style: GoogleFonts.inter(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  StatusChip(
                                    label: isSending ? 'OUTGOING' : 'INCOMING',
                                    color: isSending ? AppColors.pumpkinOrange : AppColors.successGreen,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'PEER: ${session.peerDeviceName} • ${session.files.first.formattedSize} • ${session.startTime.toString().substring(0, 16)}',
                                style: GoogleFonts.spaceMono(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        StatusChip(
                          label: session.state.name.toUpperCase(),
                          color: session.state == TransferState.completed ? AppColors.successGreen : AppColors.errorRed,
                        ),
                        if (session.state == TransferState.completed) ...[
                          const SizedBox(width: 12),
                          OutlineButtonWidget(
                            label: 'DOWNLOAD',
                            icon: LucideIcons.download,
                            onPressed: () {
                              final file = session.files.first;
                              final content = 'P2P Encrypted Chunk Transfer Payload\nFile: ${file.name}\nSize: ${file.sizeBytes} bytes\nHash: ${file.fileHash}\n';
                              downloadFileBytes(content.codeUnits, file.name);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('SAVED/DOWNLOADED FILE: ${file.name}'),
                                  backgroundColor: AppColors.successGreen,
                                ),
                              );
                            },
                          ),
                        ],
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
}
