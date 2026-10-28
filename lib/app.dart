import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'presentation/screens/dashboard/home_shell.dart';

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS UMKM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeShell(),
    );
  }
}
