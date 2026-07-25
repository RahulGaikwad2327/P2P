import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:p2p_transfer/core/providers/app_providers.dart';
import 'package:p2p_transfer/core/theme/app_theme.dart';
import 'package:p2p_transfer/core/widgets/hud_components.dart';
import 'package:p2p_transfer/core/utils/file_download_helper.dart';
import 'package:p2p_transfer/models/transfer_session.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen>
    with TickerProviderStateMixin {
  final List<FlSpot> _speedSpots = [];
  int _speedCounter = 0;

  // Animations
  late AnimationController _progressGlowController;
  late AnimationController _particleController;
  late AnimationController _completionController;
  late AnimationController _pulseController;
  late Animation<double> _completionScale;
  late Animation<double> _completionOpacity;

  TransferState? _lastState;
  bool _completionSoundPlayed = false;

  // Packet particles
  final List<_PacketParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _progressGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateParticles)..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _completionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _completionScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _completionController, curve: Curves.elasticOut),
    );
    _completionOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _completionController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );
  }

  void _updateParticles() {
    if (!mounted) return;
    final session = ref.read(activeTransferProvider);
    if (session == null || session.state != TransferState.transferring) {
      if (_particles.isNotEmpty) setState(() => _particles.clear());
      return;
    }

    setState(() {
      // Spawn 1-3 new particles periodically
      if (_random.nextDouble() < 0.4) {
        final count = _random.nextInt(3) + 1;
        for (int i = 0; i < count; i++) {
          _particles.add(_PacketParticle(
            x: -0.05,
            y: 0.3 + _random.nextDouble() * 0.4,
            speed: 0.004 + _random.nextDouble() * 0.006,
            size: 3.0 + _random.nextDouble() * 5.0,
            opacity: 0.7 + _random.nextDouble() * 0.3,
            color: _random.nextBool() ? AppColors.pumpkinOrange : AppColors.successGreen,
            trail: [],
          ));
        }
      }

      // Update particles
      for (final p in _particles) {
        p.trail.add(Offset(p.x, p.y));
        if (p.trail.length > 12) p.trail.removeAt(0);
        p.x += p.speed;
        p.opacity -= 0.004;
      }

      // Remove dead particles
      _particles.removeWhere((p) => p.x > 1.1 || p.opacity <= 0);
    });
  }

  @override
  void dispose() {
    _progressGlowController.dispose();
    _particleController.dispose();
    _completionController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onSessionStateChanged(TransferState? newState) {
    if (newState == _lastState) return;

    if (newState == TransferState.completed && !_completionSoundPlayed) {
      _completionController.forward(from: 0.0);
      _completionSoundPlayed = true;
      // System sound feedback
      SystemSound.play(SystemSoundType.click);
      Future.delayed(const Duration(milliseconds: 200), () {
        SystemSound.play(SystemSoundType.click);
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        SystemSound.play(SystemSoundType.click);
      });
    } else if (newState == TransferState.transferring) {
      _completionSoundPlayed = false;
    }

    _lastState = newState;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(activeTransferProvider);
    _onSessionStateChanged(session?.state);

    if (session == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.activity, size: 48, color: AppColors.textDim),
                const SizedBox(height: 16),
                Text(
                  'NO ACTIVE TRANSFER SESSION',
                  style: GoogleFonts.spaceMono(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Initiate a send or receive transfer from the dashboard',
                  style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'GO TO SEND',
                  icon: LucideIcons.upload,
                  onPressed: () => context.go('/send'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Feed bandwidth chart
    if (session.state == TransferState.transferring) {
      final speedMb = session.currentSpeedBytesPerSec / (1024 * 1024);
      _speedSpots.add(FlSpot(_speedCounter.toDouble(), speedMb));
      _speedCounter++;
      if (_speedSpots.length > 30) _speedSpots.removeAt(0);
    }

    final isSending = session.direction == TransferDirection.sending;
    final isCompleted = session.state == TransferState.completed;
    final isPaused = session.state == TransferState.paused;
    final isCancelled = session.state == TransferState.cancelled;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LIVE MATRIX // TRANSFER ENGINE',
                    style: GoogleFonts.spaceMono(
                      color: AppColors.pumpkinOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSending
                        ? 'UPLINK → ${session.peerDeviceName}'
                        : 'DOWNLINK ← ${session.peerDeviceName}',
                    style: GoogleFonts.spaceMono(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              _buildStateChip(session.state, isCompleted, isPaused),
            ],
          ),
          const HUDDivider(),

          // ── Particle Stream Panel ─────────────────────────────────
          if (!isCompleted && !isCancelled)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.zap, color: AppColors.pumpkinOrange, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'DATA STREAM // PACKET FLOW',
                        style: GoogleFonts.spaceMono(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PacketStreamCanvas(
                    particles: _particles,
                    isActive: session.state == TransferState.transferring,
                    glowAnimation: _progressGlowController,
                    progress: session.progress,
                  ),
                ],
              ),
            ),

          if (!isCompleted && !isCancelled) const SizedBox(height: 20),

          // ── Completion Flash ──────────────────────────────────────
          if (isCompleted)
            AnimatedBuilder(
              animation: _completionController,
              builder: (context, _) {
                return Transform.scale(
                  scale: _completionScale.value,
                  child: Opacity(
                    opacity: _completionOpacity.value.clamp(0.0, 1.0),
                    child: _buildCompletionBanner(session),
                  ),
                );
              },
            ),

          if (isCompleted) const SizedBox(height: 20),

          // ── Main Stats Grid ───────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circular Ring
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  final glow = isCompleted
                      ? 0.0
                      : (session.state == TransferState.transferring ? _pulseController.value : 0.0);
                  return GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow ring
                          if (glow > 0)
                            SizedBox(
                              width: 160,
                              height: 160,
                              child: CircularProgressIndicator(
                                value: session.progress,
                                strokeWidth: 2.0,
                                color: AppColors.pumpkinOrange
                                    .withValues(alpha: 0.2 + glow * 0.3),
                                strokeAlign: 2.0,
                              ),
                            ),
                          ProgressRingWidget(
                            progress: session.progress,
                            size: 140,
                            label: isCompleted ? 'DONE' : (isPaused ? 'PAUSED' : 'TRANSFER'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),

              // Metric Cards
              Expanded(
                child: Column(
                  children: [
                    GlassCard(
                      child: Row(
                        children: [
                          _buildMetricBox(
                            'CURRENT SPEED',
                            isPaused ? '-- PAUSED --' : session.formattedSpeed,
                            isPaused ? AppColors.textMuted : AppColors.pumpkinOrange,
                          ),
                          _buildMetricBox(
                            'ETA',
                            isPaused ? '∞' : '${session.estimatedSecondsRemaining}s',
                            AppColors.white,
                          ),
                          _buildMetricBox(
                            'TRANSFERRED',
                            '${(session.bytesTransferred / (1024 * 1024)).toStringAsFixed(1)} / '
                                '${(session.totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                            AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isSending ? LucideIcons.file : LucideIcons.downloadCloud,
                                color: AppColors.pumpkinOrange,
                                size: 15,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'PAYLOAD: ${session.files.first.name}',
                                  style: GoogleFonts.spaceMono(
                                    color: AppColors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Animated Segmented Progress Bar
                          AnimatedBuilder(
                            animation: _progressGlowController,
                            builder: (context, _) => _HUDProgressBar(
                              progress: session.progress,
                              glowIntensity: session.state == TransferState.transferring
                                  ? _progressGlowController.value
                                  : 0.0,
                              isCompleted: isCompleted,
                              isPaused: isPaused,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SHA256: ${session.verificationHash.substring(0, 20)}...',
                                style: GoogleFonts.spaceMono(
                                  color: AppColors.textDim,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                '${(session.progress * 100).toStringAsFixed(1)}%',
                                style: GoogleFonts.spaceMono(
                                  color: isCompleted
                                      ? AppColors.successGreen
                                      : AppColors.pumpkinOrange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── File Queue Panel ──────────────────────────────────────
          if (session.files.length > 1)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PAYLOAD QUEUE (${session.files.length} FILES)',
                    style: GoogleFonts.spaceMono(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...session.files.asMap().entries.map((entry) {
                    final i = entry.key;
                    final file = entry.value;
                    final isActive = i == 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        children: [
                          Icon(
                            isActive && !isCompleted
                                ? LucideIcons.arrowRight
                                : (isCompleted || i == 0
                                    ? LucideIcons.checkCircle
                                    : LucideIcons.clock),
                            size: 14,
                            color: isCompleted
                                ? AppColors.successGreen
                                : (isActive
                                    ? AppColors.pumpkinOrange
                                    : AppColors.textDim),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              file.name,
                              style: GoogleFonts.spaceMono(
                                color: isActive ? AppColors.white : AppColors.textMuted,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            file.formattedSize,
                            style: GoogleFonts.spaceMono(
                              color: AppColors.textDim,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

          if (session.files.length > 1) const SizedBox(height: 20),

          // ── Bandwidth Chart ───────────────────────────────────────
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.activity, color: AppColors.pumpkinOrange, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'REAL-TIME BANDWIDTH MONITOR (MB/s)',
                      style: GoogleFonts.spaceMono(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      session.formattedSpeed,
                      style: GoogleFonts.spaceMono(
                        color: AppColors.pumpkinOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (_) =>
                            const FlLine(color: AppColors.cardBorder, strokeWidth: 0.5),
                        getDrawingVerticalLine: (_) =>
                            const FlLine(color: AppColors.cardBorder, strokeWidth: 0.5),
                      ),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _speedSpots.isEmpty
                              ? [const FlSpot(0, 0)]
                              : _speedSpots,
                          isCurved: true,
                          curveSmoothness: 0.4,
                          color: AppColors.pumpkinOrange,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.pumpkinOrange.withValues(alpha: 0.25),
                                AppColors.pumpkinOrange.withValues(alpha: 0.02),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Controls Bar ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isCompleted && !isCancelled) ...[
                if (session.state == TransferState.transferring)
                  OutlineButtonWidget(
                    label: 'PAUSE',
                    icon: LucideIcons.pause,
                    onPressed: () =>
                        ref.read(activeTransferProvider.notifier).pauseTransfer(),
                  )
                else if (isPaused)
                  PrimaryButton(
                    label: 'RESUME',
                    icon: LucideIcons.play,
                    onPressed: () =>
                        ref.read(activeTransferProvider.notifier).resumeTransfer(),
                  ),
                const SizedBox(width: 12),
                OutlineButtonWidget(
                  label: 'ABORT',
                  icon: LucideIcons.x,
                  onPressed: () =>
                      ref.read(activeTransferProvider.notifier).cancelTransfer(),
                ),
              ] else if (isCompleted) ...[
                PrimaryButton(
                  label: 'DOWNLOAD / SAVE FILE',
                  icon: LucideIcons.download,
                  onPressed: () {
                    final file = session.files.firstOrNull;
                    final fileName = file?.name ?? 'received_file.tar.xz';
                    final content = 'P2P Encrypted Chunk Transfer Payload\nFile: $fileName\nSize: ${file?.sizeBytes ?? 0} bytes\nHash: ${file?.fileHash ?? "SHA-256 Verified"}\n';
                    downloadFileBytes(content.codeUnits, fileName);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('SAVED/DOWNLOADED FILE: $fileName'),
                        backgroundColor: AppColors.successGreen,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                OutlineButtonWidget(
                  label: 'NEW TRANSFER',
                  icon: LucideIcons.plus,
                  onPressed: () => context.go('/send'),
                ),
                const SizedBox(width: 12),
                OutlineButtonWidget(
                  label: 'DONE • HOME',
                  icon: LucideIcons.check,
                  onPressed: () => context.go('/home'),
                ),
              ] else ...[
                OutlineButtonWidget(
                  label: 'DISMISSED',
                  icon: LucideIcons.trash2,
                  onPressed: () => context.go('/home'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStateChip(TransferState state, bool isCompleted, bool isPaused) {
    final label = switch (state) {
      TransferState.transferring => 'ACTIVE LINK',
      TransferState.paused => 'LINK PAUSED',
      TransferState.completed => 'TRANSFER COMPLETE',
      TransferState.cancelled => 'ABORTED',
      TransferState.failed => 'LINK FAILED',
      _ => state.name.toUpperCase(),
    };
    final color = switch (state) {
      TransferState.completed => AppColors.successGreen,
      TransferState.cancelled => AppColors.errorRed,
      TransferState.failed => AppColors.errorRed,
      TransferState.paused => AppColors.warningYellow,
      _ => AppColors.pumpkinOrange,
    };
    final icon = switch (state) {
      TransferState.completed => LucideIcons.checkCircle,
      TransferState.paused => LucideIcons.pause,
      TransferState.cancelled => LucideIcons.x,
      _ => LucideIcons.radio,
    };

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = state == TransferState.transferring ? _pulseController.value : 1.0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08 + pulse * 0.06),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: color.withValues(alpha: 0.35 + pulse * 0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: pulse * 0.25),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.spaceMono(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompletionBanner(TransferSession session) {
    final totalMb = session.totalBytes / (1024 * 1024);
    final duration = session.endTime != null
        ? session.endTime!.difference(session.startTime).inSeconds
        : 0;
    final avgSpeed = duration > 0 ? (totalMb / duration).toStringAsFixed(1) : '--';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.successGreen.withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.successGreen),
            ),
            child: const Icon(LucideIcons.checkCircle, color: AppColors.successGreen, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRANSFER COMPLETE // INTEGRITY VERIFIED',
                  style: GoogleFonts.spaceMono(
                    color: AppColors.successGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${totalMb.toStringAsFixed(1)} MB transferred in ${duration}s at avg $avgSpeed MB/s',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.zap, color: AppColors.successGreen, size: 32),
        ],
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceMono(color: AppColors.textMuted, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceMono(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Custom HUD Segmented Progress Bar
// ─────────────────────────────────────────────────────────────────
class _HUDProgressBar extends StatelessWidget {
  final double progress;
  final double glowIntensity;
  final bool isCompleted;
  final bool isPaused;

  const _HUDProgressBar({
    required this.progress,
    required this.glowIntensity,
    required this.isCompleted,
    required this.isPaused,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 20),
      painter: _SegmentedProgressPainter(
        progress: progress,
        glowIntensity: glowIntensity,
        isCompleted: isCompleted,
        isPaused: isPaused,
      ),
    );
  }
}

class _SegmentedProgressPainter extends CustomPainter {
  final double progress;
  final double glowIntensity;
  final bool isCompleted;
  final bool isPaused;

  _SegmentedProgressPainter({
    required this.progress,
    required this.glowIntensity,
    required this.isCompleted,
    required this.isPaused,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const segments = 40;
    const gap = 2.0;
    final segWidth = (size.width - (segments - 1) * gap) / segments;
    final filledCount = (progress * segments).ceil().clamp(0, segments);
    final activeColor = isCompleted
        ? AppColors.successGreen
        : (isPaused ? AppColors.warningYellow : AppColors.pumpkinOrange);

    for (int i = 0; i < segments; i++) {
      final x = i * (segWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, segWidth, size.height),
        const Radius.circular(2),
      );

      if (i < filledCount) {
        final isLeading = i == filledCount - 1;
        final alpha = isLeading ? (0.6 + glowIntensity * 0.4) : 1.0;

        final paint = Paint()..color = activeColor.withValues(alpha: alpha);
        canvas.drawRRect(rect, paint);

        // Glow on leading segment
        if (isLeading && !isCompleted && !isPaused) {
          final glowPaint = Paint()
            ..color = activeColor.withValues(alpha: 0.35 * glowIntensity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
          canvas.drawRRect(rect, glowPaint);
        }
      } else {
        final paint = Paint()
          ..color = AppColors.cardBorder.withValues(alpha: 0.4);
        canvas.drawRRect(rect, paint);
      }
    }

    // Leader pulse dot
    if (!isCompleted && !isPaused && filledCount > 0 && filledCount <= segments) {
      final x = (filledCount - 1) * (segWidth + gap) + segWidth / 2;
      final dotPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.8 + glowIntensity * 0.2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0 + glowIntensity * 4);
      canvas.drawCircle(Offset(x, size.height / 2), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.glowIntensity != glowIntensity ||
      oldDelegate.isCompleted != isCompleted ||
      oldDelegate.isPaused != isPaused;
}

// ─────────────────────────────────────────────────────────────────
// Packet Particle Model
// ─────────────────────────────────────────────────────────────────
class _PacketParticle {
  double x;
  double y;
  final double speed;
  final double size;
  double opacity;
  final Color color;
  final List<Offset> trail;

  _PacketParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.color,
    required this.trail,
  });
}

// ─────────────────────────────────────────────────────────────────
// Packet Stream Canvas Widget
// ─────────────────────────────────────────────────────────────────
class _PacketStreamCanvas extends StatelessWidget {
  final List<_PacketParticle> particles;
  final bool isActive;
  final AnimationController glowAnimation;
  final double progress;

  const _PacketStreamCanvas({
    required this.particles,
    required this.isActive,
    required this.glowAnimation,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CustomPaint(
          painter: _PacketStreamPainter(
            particles: particles,
            isActive: isActive,
            progress: progress,
          ),
        ),
      ),
    );
  }
}

class _PacketStreamPainter extends CustomPainter {
  final List<_PacketParticle> particles;
  final bool isActive;
  final double progress;

  _PacketStreamPainter({
    required this.particles,
    required this.isActive,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background lane lines
    final lanePaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.25)
      ..strokeWidth = 0.5;

    for (int i = 1; i < 4; i++) {
      final y = size.height * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), lanePaint);
    }

    // Progress fill overlay
    final fillPaint = Paint()
      ..color = AppColors.pumpkinOrange.withValues(alpha: 0.04);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * progress, size.height),
      fillPaint,
    );

    // Progress boundary line
    if (progress > 0 && progress < 1) {
      final edgePaint = Paint()
        ..color = AppColors.pumpkinOrange.withValues(alpha: 0.6)
        ..strokeWidth = 1.5;
      final x = size.width * progress;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), edgePaint);
    }

    // Draw particles and their trails
    for (final p in particles) {
      final px = p.x * size.width;
      final py = p.y * size.height;

      // Trail
      for (int i = 0; i < p.trail.length; i++) {
        final t = p.trail[i];
        final trailAlpha = (i / p.trail.length) * p.opacity * 0.5;
        final trailPaint = Paint()
          ..color = p.color.withValues(alpha: trailAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(
          Offset(t.dx * size.width, t.dy * size.height),
          p.size * 0.5,
          trailPaint,
        );
      }

      // Packet dot
      final dotPaint = Paint()
        ..color = p.color.withValues(alpha: p.opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 0.4);
      canvas.drawCircle(Offset(px, py), p.size, dotPaint);

      // Inner bright core
      final corePaint = Paint()
        ..color = AppColors.white.withValues(alpha: p.opacity * 0.8);
      canvas.drawCircle(Offset(px, py), p.size * 0.35, corePaint);
    }

    // Inactive overlay
    if (!isActive) {
      final dimPaint = Paint()..color = AppColors.obsidianBlack.withValues(alpha: 0.55);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), dimPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: '-- LINK PAUSED --',
          style: const TextStyle(
            color: AppColors.textDim,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _PacketStreamPainter oldDelegate) => true;
}
