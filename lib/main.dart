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
    url: 'http://localhost:8000',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzQ3NzEzNjAwLCJleHAiOjE5MDU0ODAwMDB9.093ZNLA62HOB6Ja3fWO5jzG01fPi2TiVYd7UCeS4A9U',
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
