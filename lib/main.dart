import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:p2p_transfer/core/routes/app_router.dart';
import 'package:p2p_transfer/core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: P2PApp()));
}

class P2PApp extends StatelessWidget {
  const P2PApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'P2P File Transfer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}
