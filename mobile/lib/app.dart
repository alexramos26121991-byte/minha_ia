import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import 'routes/app_router.dart';
import 'theme/app_theme.dart';

/// Widget raiz do MINHA IA.
class MinhaIaApp extends StatelessWidget {
  const MinhaIaApp({super.key, GoRouter? router})
      : _router = router;

  final GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MINHA IA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: _router ?? appRouter,
      builder: (context, child) {
        // Garante que o texto não fique gigante em dispositivos com fonte maior.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: media.textScaler.clamp(maxScaleFactor: 1.3)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
