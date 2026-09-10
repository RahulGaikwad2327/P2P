import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:p2p_transfer/core/theme/app_theme.dart';
import 'package:p2p_transfer/models/peer_device.dart';


/// Primary Pumpkin Orange Flat Button with Glow on Hover
class PrimaryButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: AppColors.pumpkinOrange,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: AppColors.pumpkinOrange.withValues(alpha: 0.5),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8.0),
            onTap: widget.isLoading ? null : widget.onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.obsidianBlack,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ] else if (widget.icon != null) ...[
                    Icon(widget.icon, size: 18, color: AppColors.obsidianBlack),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.label.toUpperCase(),
                    style: GoogleFonts.spaceMono(
                      color: AppColors.obsidianBlack,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outline Button with White/Orange Border Glow
class OutlineButtonWidget extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const OutlineButtonWidget({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
  });

  @override
  State<OutlineButtonWidget> createState() => _OutlineButtonWidgetState();
}

class _OutlineButtonWidgetState extends State<OutlineButtonWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.pumpkinOrange.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: _isHovered ? AppColors.pumpkinOrange : AppColors.cardBorder,
            width: 1.2,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: AppColors.pumpkinOrange.withValues(alpha: 0.2),
                    blurRadius: 10,
                  )
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8.0),
            onTap: widget.onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 16,
                      color: _isHovered ? AppColors.pumpkinOrange : AppColors.white,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label.toUpperCase(),
                    style: GoogleFonts.spaceMono(
                      color: _isHovered ? AppColors.pumpkinOrange : AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Matte Dark GlassCard with Border Accent
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered ? (Matrix4.identity()..setTranslationRaw(0.0, -2.0, 0.0)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: _isHovered ? AppColors.pumpkinOrange.withValues(alpha: 0.6) : AppColors.cardBorder,
            width: 1.0,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: AppColors.pumpkinOrange.withValues(alpha: 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8.0),
            onTap: widget.onTap,
            child: Padding(padding: widget.padding ?? const EdgeInsets.all(16.0), child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// HUD Divider line with center marker
class HUDDivider extends StatelessWidget {
  final String? label;

  const HUDDivider({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.cardBorder)),
          if (label != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                '// ${label!.toUpperCase()}',
                style: GoogleFonts.spaceMono(
                  color: AppColors.pumpkinOrange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.cardBorder)),
          ],
        ],
      ),
    );
  }
}

/// Section Header Title
class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.pumpkinOrange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.spaceMono(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),

          // FIX
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Status Tag Chip
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    this.color = AppColors.pumpkinOrange,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: GoogleFonts.spaceMono(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated Nothing OS Dot Logo
class AnimatedLogo extends StatefulWidget {
  final double size;

  const AnimatedLogo({super.key, this.size = 48.0});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _LogoPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _LogoPainter extends CustomPainter {
  final double progress;

  _LogoPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final orangePaint = Paint()..color = AppColors.pumpkinOrange;
    final whitePaint = Paint()..color = AppColors.white.withValues(alpha: 0.9);

    // Center Node
    canvas.drawCircle(center, size.width * 0.15, orangePaint);

    // Orbiting Dots
    final radius = size.width * 0.35;
    const count = 6;
    for (int i = 0; i < count; i++) {
      final angle = (i * (2 * pi / count)) + (progress * pi);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      final p = (i % 2 == 0) ? orangePaint : whitePaint;
      canvas.drawCircle(Offset(x, y), size.width * 0.08, p);
    }
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) => oldDelegate.progress != progress;
}

/// Cyberpunk Progress Ring
class ProgressRingWidget extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final String label;

  const ProgressRingWidget({
    super.key,
    required this.progress,
    this.size = 120.0,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: AppColors.cardBorder,
              color: AppColors.pumpkinOrange,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.spaceMono(
                  color: AppColors.white,
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.spaceMono(
                  color: AppColors.textMuted,
                  fontSize: size * 0.09,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Device Card Component
class DeviceCardWidget extends StatelessWidget {
  final PeerDevice device;
  final VoidCallback? onConnect;
  final VoidCallback? onSettings;

  const DeviceCardWidget({
    super.key,
    required this.device,
    this.onConnect,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    IconData deviceIcon;
    switch (device.deviceType.toLowerCase()) {
      case 'mobile':
        deviceIcon = LucideIcons.smartphone;
        break;
      case 'tablet':
        deviceIcon = LucideIcons.tablet;
        break;
      case 'server':
        deviceIcon = LucideIcons.server;
        break;
      default:
        deviceIcon = LucideIcons.laptop;
    }

    return GlassCard(
      onTap: onConnect,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: device.isOnline ? AppColors.pumpkinOrange.withValues(alpha: 0.15) : AppColors.cardDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: device.isOnline ? AppColors.pumpkinOrange : AppColors.cardBorder,
              ),
            ),
            child: Icon(
              deviceIcon,
              color: device.isOnline ? AppColors.pumpkinOrange : AppColors.textMuted,
              size: 24,
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
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: device.isOnline ? AppColors.successGreen : AppColors.textDim,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${device.ipAddress}:${device.port} • ${device.latencyMs}ms ping',
                  style: GoogleFonts.spaceMono(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          StatusChip(
            label: device.trustStatus.name,
            color: device.trustStatus == TrustStatus.trusted
                ? AppColors.successGreen
                : (device.trustStatus == TrustStatus.blocked ? AppColors.errorRed : AppColors.warningYellow),
          ),
        ],
      ),
    );
  }
}

/// Search Bar Component
class SearchBarWidget extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;

  const SearchBarWidget({
    super.key,
    required this.hintText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: TextField(
        onChanged: onChanged,
        style: GoogleFonts.spaceMono(color: AppColors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: hintText.toUpperCase(),
          hintStyle: GoogleFonts.spaceMono(color: AppColors.textDim, fontSize: 12),
          prefixIcon: const Icon(LucideIcons.search, size: 16, color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
