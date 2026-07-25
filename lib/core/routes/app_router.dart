import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:p2p_transfer/core/widgets/cyber_shell.dart';
import 'package:p2p_transfer/features/about/about_screen.dart';
import 'package:p2p_transfer/features/devices/devices_screen.dart';
import 'package:p2p_transfer/features/history/history_screen.dart';
import 'package:p2p_transfer/features/home/home_screen.dart';
import 'package:p2p_transfer/features/not_found/not_found_screen.dart';
import 'package:p2p_transfer/features/onboarding/onboarding_screen.dart';
import 'package:p2p_transfer/features/profile/profile_screen.dart';
import 'package:p2p_transfer/features/receive/receive_screen.dart';
import 'package:p2p_transfer/features/send/send_screen.dart';
import 'package:p2p_transfer/features/settings/settings_screen.dart';
import 'package:p2p_transfer/features/splash/splash_screen.dart';
import 'package:p2p_transfer/features/transfer/transfer_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  errorBuilder: (context, state) => const NotFoundScreen(),
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => CyberShell(
        location: state.uri.toString(),
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/home',
          name: 'home',
          pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: '/send',
          name: 'send',
          pageBuilder: (context, state) => const NoTransitionPage(child: SendScreen()),
        ),
        GoRoute(
          path: '/receive',
          name: 'receive',
          pageBuilder: (context, state) => const NoTransitionPage(child: ReceiveScreen()),
        ),
        GoRoute(
          path: '/transfer',
          name: 'transfer',
          pageBuilder: (context, state) => const NoTransitionPage(child: TransferScreen()),
        ),
        GoRoute(
          path: '/history',
          name: 'history',
          pageBuilder: (context, state) => const NoTransitionPage(child: HistoryScreen()),
        ),
        GoRoute(
          path: '/devices',
          name: 'devices',
          pageBuilder: (context, state) => const NoTransitionPage(child: DevicesScreen()),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder: (context, state) => const NoTransitionPage(child: SettingsScreen()),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen()),
        ),
        GoRoute(
          path: '/about',
          name: 'about',
          pageBuilder: (context, state) => const NoTransitionPage(child: AboutScreen()),
        ),
      ],
    ),
  ],
);
