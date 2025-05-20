import 'package:flutter/material.dart';
//import 'package:flutter_application_1/screens/home.dart';
//import 'package:flutter_application_1/widgets/login.dart';
import 'package:flutter_application_1/widgets/loginpage.dart';
import 'package:flutter_application_1/widgets/responsive_scaffold.dart';
//import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  //await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: 'https://pqhuovyzslksghnkffdv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxaHVvdnl6c2xrc2dobmtmZmR2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcxODczNTUsImV4cCI6MjA2Mjc2MzM1NX0.o5sy-JI-fM1Ep5W8cSzfJ2AVmQ1dF1aUrrtE3fKwtZQ',
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocalAppTT',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
      home: ResponsiveScaffold(
        isDarkMode: _themeMode == ThemeMode.dark,
        onThemeToggle: toggleTheme,
        childBuilder: (device) => LoginPage(),
      ),
    );
  }
}
