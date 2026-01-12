import 'package:flutter/material.dart';
import 'package:local_app_tt/widgets/loginpage.dart';
import 'package:local_app_tt/widgets/responsive_wrapper.dart';
import 'package:local_app_tt/widgets/no_page_transitions.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const _themePreferenceKey = 'theme_mode_is_dark';
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themePreferenceKey);
    if (!mounted || isDark == null) {
      return;
    }
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
    _persistThemeMode(isDark);
  }

  Future<void> _persistThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePreferenceKey, isDark);
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
      onSurfaceVariant: brightness == Brightness.light
          ? const Color(0xFF3B4552)
          : baseScheme.onSurfaceVariant,
    );
    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: colorScheme,
      hintColor: brightness == Brightness.light
          ? const Color(0xFF4B5664)
          : colorScheme.onSurfaceVariant,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: NoPageTransitionsBuilder(),
          TargetPlatform.iOS: NoPageTransitionsBuilder(),
          TargetPlatform.linux: NoPageTransitionsBuilder(),
          TargetPlatform.macOS: NoPageTransitionsBuilder(),
          TargetPlatform.windows: NoPageTransitionsBuilder(),
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
