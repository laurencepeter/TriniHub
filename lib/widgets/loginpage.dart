import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/responsive_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;
ThemeMode _themeMode = ThemeMode.light;
  
  void toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }
 Future<void> signIn() async {
  if (!mounted) return;

  setState(() {
    isLoading = true;
    errorMessage = null;
  });

  final email = emailController.text.trim();
  final password = passwordController.text;

  try {
    final response = await Supabase.instance.client.auth
        .signInWithPassword(email: email, password: password);

    if (!mounted) return;

    final user = response.user;

    if (user != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
        builder: (_) => ResponsiveWrapper(
        isDarkMode: _themeMode == ThemeMode.dark, // or pass your actual dark mode state
        onThemeToggle: toggleTheme, // or your toggle logic
        ),
  ),
);
    }
  } on AuthException catch (e) {
    if (mounted) {
      setState(() => errorMessage = e.message);
    }
  } catch (e) {
    if (mounted) {
      setState(() => errorMessage = 'Unexpected error: $e');
    }
  } finally {
    if (mounted) {
      setState(() => isLoading = false);
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SignIn')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset(
              'lib/assets/images/RDLG2.1.png',
              width: 280,
              height: 375,
              fit: BoxFit.cover, 
            ),
            Text(
              "Ministry of Rural Development \n&\nLocal Government",
              textAlign: TextAlign.center,
              style: 
              TextStyle(
                fontSize: 34, // Change the size to whatever you need
                fontWeight: FontWeight.bold, // Optional: You can also add fontWeight if needed
                fontFamily: 'Arial',  // You can specify a custom font family if needed
                //color: Colors.blue,  // Set the color of the text
                letterSpacing: 2.0,  // Adjust the space between letters
              ),
            ),                
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            if (errorMessage != null)
              Text(errorMessage!, style: const TextStyle(color: Colors.red)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : signIn,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
