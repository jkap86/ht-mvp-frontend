import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';
import 'config/app_theme.dart';
import 'config/app_router.dart';
import 'config/theme_provider.dart';
import 'core/services/snack_bar_service.dart';
import 'core/services/app_lifecycle_service.dart';
import 'core/widgets/global_floating_chat.dart';
import 'features/auth/presentation/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: HypeTrainApp()));
}

class HypeTrainApp extends ConsumerWidget {
  const HypeTrainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Initialize the app lifecycle service to track background/foreground
    ref.watch(appLifecycleServiceProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Consumer(
          builder: (context, ref, _) {
            final authState = ref.watch(authStateProvider);

            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                // Only render Navigator when authenticated to avoid blocking login inputs
                if (authState.isAuthenticated)
                  Navigator(
                    onGenerateRoute: (_) => PageRouteBuilder(
                      opaque: false,
                      pageBuilder: (_, __, ___) => const GlobalFloatingChat(),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
