import 'package:flutter/material.dart';
import 'package:local_app_tt/widgets/loginpage.dart';
import 'package:local_app_tt/widgets/responsive_wrapper.dart';
import 'package:local_app_tt/widgets/smooth_page_transitions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: 'https://supabase.fireydev.com',
    anonKey:
        'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc2NjYwMjkyMCwiZXhwIjo0OTIyMjc2NTIwLCJyb2xlIjoiYW5vbiJ9.ZqSlJJnNDhwOnElfAsMHAMWS61wi2mjBCxLlUW_jbBE',
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  ThemeData _buildTheme(Brightness brightness) {
    const seedColor = Color(0xFF4C6B88);
    final baseScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    final colorScheme = baseScheme.copyWith(
      surface: brightness == Brightness.light
          ? const Color(0xFFF6F7F9)
          : const Color(0xFF121417),
      surfaceVariant: brightness == Brightness.light
          ? const Color(0xFFE6E9EE)
          : const Color(0xFF1F242B),
    );
    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: SmoothPageTransitionsBuilder(),
          TargetPlatform.iOS: SmoothPageTransitionsBuilder(),
          TargetPlatform.linux: SmoothPageTransitionsBuilder(),
          TargetPlatform.macOS: SmoothPageTransitionsBuilder(),
          TargetPlatform.windows: SmoothPageTransitionsBuilder(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trini Hub',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: _themeMode,
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final session = snapshot.data?.session;

          if (session != null) {
            return ResponsiveWrapper(
              onThemeToggle: toggleTheme,
            );
          }

          return LoginPage(
            key: ValueKey(_themeMode),
            onThemeToggle: toggleTheme,
          );
        },
      ),
    );
  }
}
