import 'dart:math';

import 'package:flutter/material.dart';
import 'package:local_app_tt/screens/dog_submissions.dart';
import 'package:local_app_tt/screens/externalservices.dart';
import 'package:local_app_tt/screens/internalservices.dart';
import 'package:local_app_tt/screens/services.dart';
import 'package:local_app_tt/screens/settings.dart';
import 'package:local_app_tt/services/dog_registration_service.dart';
import 'package:local_app_tt/widgets/bottom_tab_nav.dart';
import 'package:local_app_tt/widgets/breadcrumbs.dart';
import 'package:local_app_tt/widgets/responsive_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  final String device;

  const HomePage({
    super.key,
    required this.device,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  final DogRegistrationService _registrationService = DogRegistrationService.instance;
  late final Future<List<DogSubmission>> _submissionsFuture;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _submissionsFuture = _registrationService.fetchSubmissions();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBottomNavTap(BuildContext context, int index) {
    if (index == 0) {
      return;
    }
    Widget destination;
    switch (index) {
      case 1:
        destination = ResponsiveScaffold(
          childBuilder: (device) => ServicesPage(device: device),
        );
        break;
      case 2:
        destination = ResponsiveScaffold(
          childBuilder: (device) => InternalServices(),
        );
        break;
      case 3:
        destination = ResponsiveScaffold(
          childBuilder: (device) => ExternalServices(),
        );
        break;
      case 4:
        destination = ResponsiveScaffold(
          childBuilder: (device) => SettingsPage(device: device),
        );
        break;
      default:
        destination = ResponsiveScaffold(
          childBuilder: (device) => HomePage(device: device),
        );
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  String _resolveUserName() {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata;
    final rawName = metadata?['full_name'] ??
        metadata?['name'] ??
        metadata?['display_name'] ??
        user?.email;
    if (rawName == null) {
      return 'there';
    }
    final trimmed = rawName.toString().trim();
    if (trimmed.isEmpty) {
      return 'there';
    }
    if (trimmed.contains('@')) {
      final handle = trimmed.split('@').first;
      return handle.isEmpty ? 'there' : handle;
    }
    return trimmed;
  }

  bool _isValentineUser() {
    final email = Supabase.instance.client.auth.currentUser?.email;
    return email?.toLowerCase() == 'elan.purville@gmail.com';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showBottomNav = MediaQuery.of(context).size.width < 1200;
    final userName = _resolveUserName();
    if (_isValentineUser()) {
      return Scaffold(
        body: const _ValentineExperience(userName: 'Waffles'),
      );
    }
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.12),
              theme.colorScheme.surface,
              theme.colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Breadcrumbs(items: [BreadcrumbItem('Home')]),
                const SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                      child: Image.asset(
                        'lib/assets/images/TriniHub.png',
                        width: 26,
                        height: 26,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trini Hub',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Service command center',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: theme.colorScheme.surfaceVariant,
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, $userName',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your services, streamlined',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Pick a service lane to launch forms, track requests, and keep every workflow moving.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: const [
                            _HighlightPill(label: '24/7 service access'),
                            _HighlightPill(label: 'Real-time status updates'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Services',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _AnimatedServiceCard(
                  controller: _controller,
                  delay: 0,
                  title: 'Internal Services',
                  subtitle: 'Team tools and operational workflows',
                  icon: Icons.apartment_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResponsiveScaffold(
                          childBuilder: (device) => InternalServices(),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _AnimatedServiceCard(
                  controller: _controller,
                  delay: 0.15,
                  title: 'External Services',
                  subtitle: 'Public-facing utilities and citizen support',
                  icon: Icons.public,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResponsiveScaffold(
                          childBuilder: (device) => ExternalServices(),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Pending submissions',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _SubmissionOverviewCard(submissionsFuture: _submissionsFuture),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: showBottomNav
          ? BottomNavBar(
              currentIndex: 0,
              onTap: (index) => _handleBottomNavTap(context, index),
            )
          : null,
    );
  }
}

class _ValentineExperience extends StatefulWidget {
  final String userName;

  const _ValentineExperience({required this.userName});

  @override
  State<_ValentineExperience> createState() => _ValentineExperienceState();
}

class _ValentineExperienceState extends State<_ValentineExperience>
    with TickerProviderStateMixin {
  late final AnimationController _promptController;
  late final AnimationController _catController;
  late final AnimationController _waffleController;
  final Random _random = Random();
  Offset _noButtonOffset = const Offset(0.25, 0.65);
  int _dodges = 0;
  int _questionIndex = 0;
  bool _showSummary = false;
  bool _otherSelected = false;
  final TextEditingController _otherController = TextEditingController();
  late final List<_ValentineQuestion> _questions;
  late final List<String?> _answers;

  @override
  void initState() {
    super.initState();
    _questions = const [
      _ValentineQuestion(
        prompt: 'Where did we meet?',
        options: ['Bedroom', 'House Party', 'School', 'Friend'],
      ),
      _ValentineQuestion(
        prompt: 'How long have we been together?',
        options: ['4 years', 'Since birth', '1991', '6 years'],
      ),
      _ValentineQuestion(
        prompt: 'What item did we buy at the Aqurium?',
        options: ['Chinese', 'Hot chocolato', 'Nothing', 'Lotties'],
      ),
      _ValentineQuestion(
        prompt: 'Where do you want to travel next?',
        options: ['Mexico', 'Colombia', 'Peru', 'Other'],
        allowsOther: true,
        otherPrompt: 'If other, tell me where we should go.',
      ),
      _ValentineQuestion(
        prompt: 'Where did first realize you really loved me?',
        options: ['Now', 'Later', 'Birth', 'After the first "D"', 'Other'],
        allowsOther: true,
        otherPrompt: 'If other, please state why.',
      ),
      _ValentineQuestion(
        prompt: 'Will you be my Valentine?',
        options: ['Yes', 'No'],
        isFinal: true,
      ),
    ];
    _answers = List<String?>.filled(_questions.length, null);
    _promptController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _catController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _waffleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _promptController.dispose();
    _catController.dispose();
    _waffleController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  void _advanceQuestion() {
    if (_questionIndex < _questions.length - 1) {
      setState(() {
        _questionIndex += 1;
        _otherSelected = false;
        _otherController.clear();
      });
    }
  }

  void _selectOption(String option) {
    final question = _questions[_questionIndex];
    if (question.isFinal) {
      if (option == 'Yes') {
        setState(() {
          _answers[_questionIndex] = option;
          _showSummary = true;
        });
        _showCongratsDialog();
      }
      return;
    }

    if (question.allowsOther && option == 'Other') {
      setState(() {
        _otherSelected = true;
      });
      return;
    }

    setState(() {
      _answers[_questionIndex] = option;
    });
    _advanceQuestion();
  }

  void _submitOtherAnswer() {
    final response = _otherController.text.trim();
    if (response.isEmpty) {
      return;
    }
    setState(() {
      _answers[_questionIndex] = response;
    });
    _advanceQuestion();
  }

  Future<void> _showCongratsDialog() async {
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFF1C6),
                  Color(0xFFFFE1F2),
                  Color(0xFFE5FBFF),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉✨💖', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 12),
                Text(
                  'Congratulations, Waffles!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFB61C4F),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Congratulations on making the right choice!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF8B3A62),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  child: const Text('Seal the yes 💞'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _advanceQuestion() {
    if (_questionIndex < _questions.length - 1) {
      setState(() {
        _questionIndex += 1;
        _otherSelected = false;
        _otherController.clear();
      });
    }
  }

  void _selectOption(String option) {
    final question = _questions[_questionIndex];
    if (question.isFinal) {
      if (option == 'Yes') {
        setState(() {
          _answers[_questionIndex] = option;
          _showSummary = true;
        });
        _showCongratsDialog();
      } else {
        _dodgeNoButton();
      }
      return;
    }

    if (question.allowsOther && option == 'Other') {
      setState(() {
        _otherSelected = true;
      });
      return;
    }

    setState(() {
      _answers[_questionIndex] = option;
    });
    _advanceQuestion();
  }

  void _submitOtherAnswer() {
    final response = _otherController.text.trim();
    if (response.isEmpty) {
      return;
    }
    setState(() {
      _answers[_questionIndex] = response;
    });
    _advanceQuestion();
  }

  Future<void> _showCongratsDialog() async {
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFF1C6),
                  Color(0xFFFFE1F2),
                  Color(0xFFE5FBFF),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉✨💖', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 12),
                Text(
                  'Congratulations, Waffles!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFB61C4F),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Congratulations on making the right choice!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF8B3A62),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  child: const Text('Seal the yes 💞'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFinalQuestion = _questionIndex == _questions.length - 1;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFE4EC),
            Color(0xFFFFF7F9),
            Color(0xFFFFEED7),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            return Stack(
              children: [
                Positioned(
                  top: 24,
                  left: 24,
                  child: _AnimatedCat(
                    controller: _catController,
                    label: 'Poppy',
                    accentColor: const Color(0xFFE75480),
                    alignment: Alignment.topLeft,
                  ),
                ),
                Positioned(
                  top: 24,
                  right: 24,
                  child: _AnimatedCat(
                    controller: _catController,
                    label: 'Mochi',
                    accentColor: const Color(0xFFFF9A3D),
                    alignment: Alignment.topRight,
                  ),
                ),
                Align(
                  alignment: const Alignment(0, -0.2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _promptController,
                        builder: (context, child) {
                          final pulse = 1 + (_promptController.value * 0.08);
                          return Transform.scale(
                            scale: pulse,
                            child: child,
                          );
                        },
                        child: Text(
                          _showSummary ? 'All your answers, Waffles!' : _questions[_questionIndex].prompt,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFB61C4F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _showSummary
                            ? 'A perfect recap of every sweet answer.'
                            : 'Question ${_questionIndex + 1} of ${_questions.length}.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF8B3A62),
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: const Alignment(0, 0.1),
                  child: _WaffleBaby(controller: _waffleController),
                ),
                if (_showSummary)
                  Positioned(
                    top: height * 0.42,
                    left: width * 0.08,
                    right: width * 0.08,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < _questions.length; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${i + 1}. ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFB61C4F),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _questions[i].prompt,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _answers[i] ?? '—',
                                          style: const TextStyle(color: Color(0xFF8B3A62)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                else if (isFinalQuestion) ...[
                  Positioned(
                    top: height * 0.56,
                    left: width * 0.22,
                    child: AnimatedBuilder(
                      animation: _promptController,
                      builder: (context, child) {
                        final glow = 0.92 + (_promptController.value * 0.1);
                        return Transform.scale(scale: glow, child: child);
                      },
                      child: ElevatedButton(
                        onPressed: () => _selectOption('Yes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 24),
                          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                          elevation: 12,
                        ),
                        child: const Text('Yes 💖'),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 260),
                    left: width * _noButtonOffset.dx,
                    top: height * _noButtonOffset.dy,
                    child: MouseRegion(
                      onEnter: (_) => _dodgeNoButton(),
                      child: GestureDetector(
                        onTap: _dodgeNoButton,
                        child: OutlinedButton(
                          onPressed: _dodgeNoButton,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFB61C4F),
                            side: const BorderSide(color: Color(0xFFB61C4F), width: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            shape:
                                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: const Text('No'),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Positioned(
                    top: height * 0.48,
                    left: width * 0.12,
                    right: width * 0.12,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          for (final option in _questions[_questionIndex].options)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _selectOption(option),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF9A3D),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(option),
                                ),
                              ),
                            ),
                          if (_otherSelected) ...[
                            const SizedBox(height: 10),
                            Text(
                              _questions[_questionIndex].otherPrompt ?? '',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF8B3A62)),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _otherController,
                              decoration: InputDecoration(
                                hintText: 'Type your answer here...',
                                filled: true,
                                fillColor: const Color(0xFFFFF4F7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submitOtherAnswer,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE91E63),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text('Save answer'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedCat extends StatelessWidget {
  final AnimationController controller;
  final String label;
  final Color accentColor;
  final Alignment alignment;

  const _AnimatedCat({
    required this.controller,
    required this.label,
    required this.accentColor,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final bob = sin(controller.value * pi * 2) * 6;
        return Transform.translate(offset: Offset(0, bob), child: child);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Text('🐱', style: TextStyle(fontSize: 38)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFB61C4F)),
          ),
        ],
      ),
    );
  }
}

class _WaffleBaby extends StatelessWidget {
  final AnimationController controller;

  const _WaffleBaby({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final tilt = sin(controller.value * pi * 2) * 0.05;
        return Transform.rotate(angle: tilt, child: child);
      },
      child: Container(
        width: 160,
        height: 170,
        decoration: BoxDecoration(
          color: const Color(0xFFFFD18A),
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: CustomPaint(
                  painter: _WaffleGridPainter(),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('👶', style: TextStyle(fontSize: 38)),
                  SizedBox(height: 4),
                  Text('Waffle Baby', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const Positioned(
              left: 36,
              top: 50,
              child: Icon(Icons.favorite, color: Color(0xFFE75480), size: 16),
            ),
            const Positioned(
              right: 36,
              top: 46,
              child: Icon(Icons.favorite, color: Color(0xFFE75480), size: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaffleGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF5B85E)
      ..strokeWidth = 2;
    const spacing = 22.0;
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ValentineQuestion {
  final String prompt;
  final List<String> options;
  final bool allowsOther;
  final String? otherPrompt;
  final bool isFinal;

  const _ValentineQuestion({
    required this.prompt,
    required this.options,
    this.allowsOther = false,
    this.otherPrompt,
    this.isFinal = false,
  });
}

class _HighlightPill extends StatelessWidget {
  final String label;

  const _HighlightPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _AnimatedServiceCard extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AnimatedServiceCard({
    required this.controller,
    required this.delay,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(delay, 1, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(animation),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                    child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubmissionOverviewCard extends StatelessWidget {
  final Future<List<DogSubmission>> submissionsFuture;

  const _SubmissionOverviewCard({required this.submissionsFuture});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<DogSubmission>>(
      future: submissionsFuture,
      builder: (context, snapshot) {
        final submissions = snapshot.data ?? [];
        final pendingCount = submissions.where((item) => item.status == 'pending').length;
        final statusLabel = pendingCount > 0
            ? '$pendingCount pending approval'
            : submissions.isEmpty
                ? 'No submissions yet'
                : 'All submissions approved';
        final statusColor = pendingCount > 0
            ? Colors.orange
            : submissions.isEmpty
                ? theme.hintColor
                : Colors.green;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                    child: Icon(Icons.pets, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dog Registration',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusLabel,
                          style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      pendingCount > 0 ? 'Pending' : 'Up to date',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loading status...',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                  ],
                )
              else if (snapshot.hasError)
                Text(
                  'Unable to load submissions.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                )
              else if (submissions.isEmpty)
                Text(
                  'Start a new submission to track its status from here.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                )
              else
                Text(
                  '${submissions.length} submission${submissions.length == 1 ? '' : 's'} total.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResponsiveScaffold(
                          childBuilder: (device) => const DogSubmissionsScreen(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View submissions'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
