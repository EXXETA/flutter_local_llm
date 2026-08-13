import 'package:flutter/material.dart';

import 'core/router/app_router.dart';

class App extends StatelessWidget {
  const App({super.key, required this.isModelInstalled});

  final bool isModelInstalled;

  @override
  Widget build(BuildContext context) {
    final router = AppRouter(isModelInstalled: isModelInstalled);

    return MaterialApp.router(
      title: 'Local LLM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4285F4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4285F4),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: router.config(),
    );
  }
}
