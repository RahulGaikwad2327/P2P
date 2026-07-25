import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:p2p_transfer/core/theme/app_theme.dart';
import 'package:p2p_transfer/core/widgets/dot_grid_background.dart';
import 'package:p2p_transfer/core/widgets/hud_components.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final List<String> _bootLogs = [];
  int _logIndex = 0;
  Timer? _bootTimer;
  Timer? _navTimer;

  final List<String> _diagnosticLogs = [
    'INITIALIZING FLUTTER SECURE STORAGE...',
    'GENERATING ECDH-P256 KEY PAIR...',
    'RESOLVING LOCAL NETWORK INTERFACE...',
    'CONNECTING TO SIGNALING SERVER [WS:3000]...',
    'SPAWNING GO CORE ENGINE [LOCALHOST:9000]...',
    'TLS 1.3 HANDSHAKE • AES-256-GCM READY',
    'SYSTEM READY • P2P STACK ONLINE',
  ];

  @override
  void initState() {
    super.initState();
    _startBootSequence();
  }

  void _startBootSequence() {
    _bootTimer = Timer.periodic(const Duration(milliseconds: 350), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_logIndex < _diagnosticLogs.length) {
        setState(() {
          _bootLogs.add(_diagnosticLogs[_logIndex]);
          _logIndex++;
        });
      } else {
        timer.cancel();
        _navTimer = Timer(const Duration(milliseconds: 600), () {
          if (mounted) {
            context.go('/onboarding');
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _bootTimer?.cancel();
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      body: DotGridBackground(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AnimatedLogo(size: 80),
                const SizedBox(height: 32),
                Text(
                  'P2P FILE TRANSFER',
                  style: GoogleFonts.spaceMono(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'FAST • SECURE • DIRECT • NO SERVERS',
                  style: GoogleFonts.spaceMono(
                    color: AppColors.pumpkinOrange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 8, height: 8, color: AppColors.pumpkinOrange),
                          const SizedBox(width: 8),
                          Text(
                            'BOOT DIAGNOSTICS LOG',
                            style: GoogleFonts.spaceMono(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const HUDDivider(),
                      SizedBox(
                        height: 110,
                        child: ListView.builder(
                          itemCount: _bootLogs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Text(
                                '> ${_bootLogs[index]}',
                                style: GoogleFonts.spaceMono(
                                  color: index == _bootLogs.length - 1
                                      ? AppColors.pumpkinOrange
                                      : AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
