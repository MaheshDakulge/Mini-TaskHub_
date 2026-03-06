import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  await ConnectivityService.instance.initialize();

  try {
    await Supabase.initialize(
      url: 'https://nhthtxrizqgigbmiqjps.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5odGh0eHJpenFnaWdibWlxanBzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI1NTUxNjUsImV4cCI6MjA4ODEzMTE2NX0.4aDsZIdAt1RAVuDIljtKQZHjmUzHedXjaCmKQlWzY0U',
    );
  } catch (e) {
    debugPrint('Supabase init failed, running offline: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: MyApp(savedThemeMode: savedThemeMode),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AdaptiveThemeMode? savedThemeMode;
  const MyApp({super.key, this.savedThemeMode});

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: AppTheme.lightTheme,
      dark: AppTheme.darkTheme,
      initial: savedThemeMode ?? AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => MaterialApp.router(
        title: 'Mini TaskHub',
        theme: theme,
        darkTheme: darkTheme,
        routerConfig: AppRouter.createRouter(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
