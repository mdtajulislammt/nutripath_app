import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/app_state_provider.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/google_login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'widgets/custom_nav_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase.initializeApp error: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppStateProvider(),
      child: const NutriPathApp(),
    ),
  );
}

class NutriPathApp extends StatelessWidget {
  const NutriPathApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();

    return MaterialApp(
      title: 'NutriPath',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: state.isDark ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const GoogleLoginScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/dashboard': (context) => const CustomNavShell(),
      },
    );
  }
}
