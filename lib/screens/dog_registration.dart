import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DogRegistrationScreen extends StatefulWidget {
  const DogRegistrationScreen({super.key});

  static Route<void> route() {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, animation, secondaryAnimation) => const DogRegistrationScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<DogRegistrationScreen> createState() => _DogRegistrationScreenState();
}

class _DogRegistrationScreenState extends State<DogRegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _ownerContactController = TextEditingController();
  final TextEditingController _dogNameController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _microchipController = TextEditingController();
  final TextEditingController _vaccinationController = TextEditingController();
  final TextEditingController _temperamentController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final Set<String> _traits = {};

  bool _neutered = false;
  double _activityLevel = 3;
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _ownerNameController.dispose();
    _ownerContactController.dispose();
    _dogNameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _microchipController.dispose();
    _vaccinationController.dispose();
    _temperamentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      _submitting = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Dog Registration',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D1B2A), Color(0xFF1B263B), Color(0xFF415A77)],
            ),
          ),
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _submitted ? _buildSuccessState(theme) : _buildForm(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 720;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 18),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Flex(
                            direction: isWide ? Axis.horizontal : Axis.vertical,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildTextField(_ownerNameController, 'Owner name', 'Who is responsible for this dog?')),
                              SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 12),
                              Expanded(child: _buildTextField(_ownerContactController, 'Contact number or email', 'We will use this to follow up.')),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Flex(
                            direction: isWide ? Axis.horizontal : Axis.vertical,
                            children: [
                              Expanded(child: _buildTextField(_dogNameController, "Dog's name", 'Call name used daily.')),
                              SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 12),
                              Expanded(child: _buildTextField(_breedController, 'Breed or mix', 'e.g. German Shepherd / Mix')),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Flex(
                            direction: isWide ? Axis.horizontal : Axis.vertical,
                            children: [
                              Expanded(child: _buildTextField(_ageController, 'Age', 'Years & months')),
                              SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 12),
                              Expanded(child: _buildTextField(_weightController, 'Weight', 'kg or lbs')),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Flex(
                            direction: isWide ? Axis.horizontal : Axis.vertical,
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  _microchipController,
                                  'Microchip ID',
                                  'Optional but recommended.',
                                  isRequired: false,
                                ),
                              ),
                              SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 12),
                              Expanded(child: _buildTextField(_vaccinationController, 'Vaccination status', 'Latest shots & dates.')),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildSectionCard(
                            title: 'Temperament notes',
                            child: Column(
                              children: [
                                _buildTextField(
                                  _temperamentController,
                                  'Energy & behaviour',
                                  'Friendly, anxious, reactive to other dogs... ',
                                  maxLines: 2,
                                  isRequired: false,
                                ),
                                const SizedBox(height: 10),
                                _buildTextField(
                                  _notesController,
                                  'Care preferences',
                                  'Feeding window, medication, triggers... ',
                                  maxLines: 3,
                                  isRequired: false,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildSectionCard(
                            title: 'Wellness snapshot',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Neutered / Spayed'),
                                  subtitle: const Text('Tell us if the dog has been fixed'),
                                  value: _neutered,
                                  onChanged: (value) => setState(() => _neutered = value),
                                ),
                                const SizedBox(height: 6),
                                Text('Activity level', style: theme.textTheme.titleMedium),
                                Slider(
                                  value: _activityLevel,
                                  min: 1,
                                  max: 5,
                                  divisions: 4,
                                  label: ['Calm', 'Chill', 'Balanced', 'Playful', 'High'][_activityLevel.round() - 1],
                                  onChanged: (value) => setState(() => _activityLevel = value),
                                ),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _buildChip('House trained'),
                                    _buildChip('Good with kids'),
                                    _buildChip('Prefers adults'),
                                    _buildChip('Social with dogs'),
                                    _buildChip('Special diet'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            width: double.infinity,
                            child: FilledButton.icon(
                              icon: _submitting
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                                      ),
                                    )
                                  : const Icon(Icons.pets),
                              label: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Text(_submitting ? 'Submitting...' : 'Save registration'),
                              ),
                              onPressed: _submitting ? null : _submit,
                              style: FilledButton.styleFrom(
                                textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
                                backgroundColor: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dog Database Intake',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Capture the essentials in one modern view. Clean inputs, quick toggles, and smooth micro-interactions keep registrations fast.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) => LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.white12,
              color: theme.colorScheme.secondary,
              minHeight: 6,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String helper, {
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12),
          ),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'Required field';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildChip(String label) {
    return FilterChip(
      label: Text(label),
      selected: _traits.contains(label),
      showCheckmark: false,
      onSelected: (value) {
        setState(() {
          if (value) {
            _traits.add(label);
          } else {
            _traits.remove(label);
          }
        });
      },
    );
  }

  Widget _buildSuccessState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                  child: Icon(Icons.verified_rounded, color: theme.colorScheme.primary, size: 32),
                ),
                const SizedBox(height: 14),
                Text(
                  'Registration saved',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'We logged this dog into the database with the details provided.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 18),
                _buildSummaryTile('Owner', _ownerNameController.text, Icons.person_outline),
                _buildSummaryTile('Dog', _dogNameController.text, Icons.pets_outlined),
                _buildSummaryTile('Breed', _breedController.text, Icons.badge_outlined),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
                    child: Text('Close'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTile(String title, String value, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(value.isEmpty ? 'Not provided' : value),
    );
  }
}
