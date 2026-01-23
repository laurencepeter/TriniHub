import 'dart:async';

import 'package:flutter/material.dart';
import 'package:local_app_tt/services/auth_service.dart';
import 'package:local_app_tt/services/dog_registration_service.dart';
import 'package:local_app_tt/utils/error_mapper.dart';
import 'package:local_app_tt/utils/validators.dart';
import 'package:local_app_tt/widgets/responsive_wrapper.dart';

class RegisterPage extends StatefulWidget {
  final void Function(bool) onThemeToggle;

  const RegisterPage({super.key, required this.onThemeToggle});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedRegionId;
  bool _acceptTerms = false;
  bool _isSubmitting = false;
  bool _isResendingVerification = false;
  String? _errorMessage;
  bool _isAwaitingVerification = false;
  String? _verificationStatus;
  Timer? _verificationTimer;

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _startVerificationPolling({required String email, required String password}) {
    _verificationTimer?.cancel();
    setState(() {
      _isAwaitingVerification = true;
      _verificationStatus = 'Waiting for email confirmation...';
    });
    _verificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final authService = AuthService();
        final user = await authService.signIn(email: email, password: password);
        if (!mounted) return;
        if (user != null) {
          timer.cancel();
          setState(() => _verificationStatus = 'User verified! Signing you in...');
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ResponsiveWrapper(onThemeToggle: widget.onThemeToggle),
            ),
          );
        }
      } catch (error) {
        if (!mounted) return;
        final message = mapSupabaseError(error);
        if (message.toLowerCase().contains('confirm')) {
          return;
        }
        timer.cancel();
        setState(() {
          _isAwaitingVerification = false;
          _verificationStatus = null;
          _errorMessage = message;
        });
      }
    });
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    if (!_acceptTerms) {
      setState(() => _errorMessage = 'Please accept the terms to continue.');
      return;
    }
    _verificationTimer?.cancel();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _isAwaitingVerification = false;
      _isResendingVerification = false;
      _verificationStatus = null;
    });
    try {
      final authService = AuthService();
      final outcome = await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        regionId: _selectedRegionId,
      );
      if (!mounted) return;
      if (outcome.requiresEmailVerification) {
        _startVerificationPolling(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        return;
      }
      if (outcome.user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResponsiveWrapper(onThemeToggle: widget.onThemeToggle),
          ),
        );
      } else {
        setState(() => _errorMessage = 'Unable to create your account. Please try again.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = mapSupabaseError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _resendVerification() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || _isResendingVerification) {
      return;
    }
    setState(() {
      _isResendingVerification = true;
      _errorMessage = null;
      _verificationStatus = 'Resending confirmation email...';
    });
    try {
      final authService = AuthService();
      await authService.resendSignUpEmail(email: email);
      if (!mounted) return;
      setState(() {
        _verificationStatus = 'Confirmation email resent. Please check your inbox.';
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = mapSupabaseError(error);
          _verificationStatus = 'Waiting for email confirmation...';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isResendingVerification = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create account'),
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
                      'Let’s get you set up',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your account to register dogs, manage tags, and track services.',
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
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        helperText: 'Minimum 8 characters',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) => Validators.password(value, minLength: 8),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) => Validators.confirmPassword(value, _passwordController.text),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Profile details',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _firstNameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'First name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) => Validators.requiredField(value, label: 'First name'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lastNameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Last name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) => Validators.requiredField(value, label: 'Last name'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      decoration: const InputDecoration(
                        labelText: 'Phone (optional)',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<LookupOption>>(
                      future: DogRegistrationService.instance.fetchRegions(),
                      builder: (context, snapshot) {
                        final regions = snapshot.data ?? [];
                        return DropdownButtonFormField<String>(
                          value: _selectedRegionId,
                          items: regions
                              .map((region) => DropdownMenuItem(
                                    value: region.id,
                                    child: Text(region.name),
                                  ))
                              .toList(),
                          onChanged: (value) => setState(() => _selectedRegionId = value),
                          decoration: const InputDecoration(
                            labelText: 'Region (optional)',
                            prefixIcon: Icon(Icons.map_outlined),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      value: _acceptTerms,
                      onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('I agree to the terms and privacy policy'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_isAwaitingVerification) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(
                        _verificationStatus ?? 'Waiting for email confirmation...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _isResendingVerification ? null : _resendVerification,
                        child: _isResendingVerification
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Resend confirmation email'),
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: (_isSubmitting || _isAwaitingVerification) ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              )
                            : const Text('Create account'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back to login'),
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
