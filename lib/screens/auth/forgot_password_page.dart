import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:local_app_tt/utils/error_mapper.dart';
import 'package:local_app_tt/utils/validators.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  bool _devMode = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    final email = _emailController.text.trim();
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: dotenv.env['SUPABASE_RESET_REDIRECT'] ?? 'trinihub://recovery',
      );

      if (_devMode) {
        final url = dotenv.env['SUPABASE_URL'];
        final serviceKey = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'];
        if (url != null && serviceKey != null) {
          final adminClient = SupabaseClient(url, serviceKey);
          final response = await adminClient.auth.admin.generateLink(
            type: GenerateLinkType.recovery,
            email: email,
            redirectTo: dotenv.env['SUPABASE_RESET_REDIRECT'] ?? 'trinihub://recovery',
          );
          debugPrint('Recovery link (dev mode): ${response.properties.actionLink}');
          debugPrint('Recovery link (dev mode): ${response.properties['action_link']}');
        } else {
          debugPrint('Dev mode enabled: set SUPABASE_SERVICE_ROLE_KEY to log recovery links.');
        }
      }

      if (mounted) {
        setState(() => _message = 'Check your email to set your password.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message = mapSupabaseError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset or activate account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set your password',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your email to receive a password setup link.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: Validators.email,
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _devMode,
                        title: const Text('Dev mode: log recovery link to console'),
                        onChanged: (value) => setState(() => _devMode = value),
                      ),
                    ],
                    if (_message != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _message!,
                        style: TextStyle(
                          color: _message!.toLowerCase().contains('check your email')
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              )
                            : const Text('Send reset link'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
