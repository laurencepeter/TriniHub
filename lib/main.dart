import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:local_app_tt/widgets/auth_gate.dart';
import 'package:local_app_tt/widgets/base_version_footer.dart';
import 'package:local_app_tt/widgets/no_page_transitions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_app_tt/services/theme_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? const String.fromEnvironment('SUPABASE_URL');
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? const String.fromEnvironment('SUPABASE_ANON_KEY');
  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw FlutterError('Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    ThemeSettings.instance.load();
  }

  void _handleThemeToggle(bool isDark) {
    ThemeSettings.instance.setThemeMode(isDark);
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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeSettings.instance.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Trini Hub',
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: themeMode,
          builder: (context, child) {
            return Stack(
              children: [
                if (child != null) child,
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: BaseVersionFooter(),
                  ),
                ),
              ],
            );
          },
          home: AuthGate(
            key: ValueKey(themeMode),
            onThemeToggle: _handleThemeToggle,
          ),
        );
      },
    );
  }
}
