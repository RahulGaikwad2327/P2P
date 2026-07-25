import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:p2p_transfer/core/providers/app_providers.dart';
import 'package:p2p_transfer/core/theme/app_theme.dart';
import 'package:p2p_transfer/core/widgets/dot_grid_background.dart';
import 'package:p2p_transfer/core/widgets/hud_components.dart';

class CyberShell extends ConsumerWidget {
  final Widget child;
  final String location;

  const CyberShell({
    super.key,
    required this.child,
    required this.location,
  });

  int _getSelectedIndex(String loc) {
    if (loc.startsWith('/send')) return 1;
    if (loc.startsWith('/receive')) return 2;
    if (loc.startsWith('/transfer')) return 3;
    if (loc.startsWith('/history')) return 4;
    if (loc.startsWith('/devices')) return 5;
    if (loc.startsWith('/settings')) return 6;
    if (loc.startsWith('/profile')) return 7;
    if (loc.startsWith('/about')) return 8;
    return 0; // Home
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/send');
        break;
      case 2:
        context.go('/receive');
        break;
      case 3:
        context.go('/transfer');
        break;
      case 4:
        context.go('/history');
        break;
      case 5:
        context.go('/devices');
        break;
      case 6:
        context.go('/settings');
        break;
      case 7:
        context.go('/profile');
        break;
      case 8:
        context.go('/about');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTransfer = ref.watch(activeTransferProvider);
    final selectedIndex = _getSelectedIndex(location);

    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      body: DotGridBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 768;

            return Column(
              children: [
                // Top Cyberpunk HUD Header
                _buildTopHUDHeader(context, activeTransfer != null),
                const Divider(height: 1, color: AppColors.cardBorder),

                // Main Body Area
                Expanded(
                  child: Row(
                    children: [
                      // Navigation Rail for Desktop/Tablet
                      if (isDesktop) ...[
                        _buildNavigationRail(context, selectedIndex),
                        const VerticalDivider(width: 1, color: AppColors.cardBorder),
                      ],

                      // Active Page View
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: child,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Navigation for Mobile
                if (!isDesktop) ...[
                  const Divider(height: 1, color: AppColors.cardBorder),
                  _buildBottomNavigationBar(context, selectedIndex),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopHUDHeader(BuildContext context, bool hasActiveTransfer) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.cardDark.withValues(alpha: 0.8),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.go('/home'),
            child: Row(
              children: [
                const AnimatedLogo(size: 24),
                const SizedBox(width: 12),
                Text(
                  'P2P',
                  style: GoogleFonts.spaceMono(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                Text(
                  ' // DIRECT',
                  style: GoogleFonts.spaceMono(
                    color: AppColors.pumpkinOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (hasActiveTransfer)
            InkWell(
              onTap: () => context.go('/transfer'),
              child: const StatusChip(
                label: 'TRANSFER ACTIVE',
                color: AppColors.pumpkinOrange,
                icon: LucideIcons.arrowUpRight,
              ),
            ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.obsidianBlack,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.successGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'SYS_ONLINE',
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
    );
  }

  Widget _buildNavigationRail(BuildContext context, int selectedIndex) {
    final items = [
      {'icon': LucideIcons.home, 'label': 'HOME'},
      {'icon': LucideIcons.upload, 'label': 'SEND'},
      {'icon': LucideIcons.download, 'label': 'RECEIVE'},
      {'icon': LucideIcons.activity, 'label': 'TRANSFER'},
      {'icon': LucideIcons.clock, 'label': 'HISTORY'},
      {'icon': LucideIcons.hardDrive, 'label': 'DEVICES'},
      {'icon': LucideIcons.settings, 'label': 'SETTINGS'},
      {'icon': LucideIcons.user, 'label': 'PROFILE'},
      {'icon': LucideIcons.info, 'label': 'ABOUT'},
    ];

    return Container(
      width: 180,
      color: AppColors.cardDark.withValues(alpha: 0.5),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final isSelected = selectedIndex == index;
                final item = items[index];

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.pumpkinOrange.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? AppColors.pumpkinOrange : Colors.transparent,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      item['icon'] as IconData,
                      size: 16,
                      color: isSelected ? AppColors.pumpkinOrange : AppColors.textMuted,
                    ),
                    title: Text(
                      item['label'] as String,
                      style: GoogleFonts.spaceMono(
                        color: isSelected ? AppColors.white : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onTap: () => _onItemTapped(context, index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, int selectedIndex) {
    final items = [
      {'icon': LucideIcons.home, 'label': 'HOME'},
      {'icon': LucideIcons.upload, 'label': 'SEND'},
      {'icon': LucideIcons.download, 'label': 'RECV'},
      {'icon': LucideIcons.activity, 'label': 'XFER'},
      {'icon': LucideIcons.clock, 'label': 'HIST'},
    ];

    return Container(
      height: 60,
      color: AppColors.cardDark,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isSelected = selectedIndex == index;
          final item = items[index];

          return InkWell(
            onTap: () => _onItemTapped(context, index),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item['icon'] as IconData,
                  size: 18,
                  color: isSelected ? AppColors.pumpkinOrange : AppColors.textMuted,
                ),
                const SizedBox(height: 4),
                Text(
                  item['label'] as String,
                  style: GoogleFonts.spaceMono(
                    color: isSelected ? AppColors.pumpkinOrange : AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
