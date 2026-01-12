import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_app_tt/services/dog_registration_service.dart';

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

  final DogRegistrationService _registrationService = DogRegistrationService.instance;

  final TextEditingController _ownerFirstNameController = TextEditingController();
  final TextEditingController _ownerLastNameController = TextEditingController();
  final TextEditingController _ownerPhoneController = TextEditingController();
  final TextEditingController _ownerEmailController = TextEditingController();
  final TextEditingController _ownerNationalIdController = TextEditingController();
  final TextEditingController _ownerAddressLine1Controller = TextEditingController();
  final TextEditingController _ownerAddressLine2Controller = TextEditingController();
  final TextEditingController _dogNumberController = TextEditingController();
  final TextEditingController _dogNameController = TextEditingController();
  final TextEditingController _dogColorController = TextEditingController();
  final TextEditingController _microchipController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<LookupOption> _breeds = [];
  List<LookupOption> _regions = [];
  String? _selectedBreedId;
  String? _selectedRegionId;
  String _selectedSex = 'unknown';
  DateTime? _dogDob;
  DateTime? _ownershipStartDate;

  bool _loadingLookups = true;
  String? _lookupError;
  bool _submitting = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  @override
  void dispose() {
    _ownerFirstNameController.dispose();
    _ownerLastNameController.dispose();
    _ownerPhoneController.dispose();
    _ownerEmailController.dispose();
    _ownerNationalIdController.dispose();
    _ownerAddressLine1Controller.dispose();
    _ownerAddressLine2Controller.dispose();
    _dogNumberController.dispose();
    _dogNameController.dispose();
    _dogColorController.dispose();
    _microchipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    try {
      final results = await Future.wait([
        _registrationService.fetchBreeds(),
        _registrationService.fetchRegions(),
      ]);
      if (!mounted) return;
      setState(() {
        _breeds = results[0] as List<LookupOption>;
        _regions = results[1] as List<LookupOption>;
        _loadingLookups = false;
        _lookupError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingLookups = false;
        _lookupError = 'Unable to load dropdown options.';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
    });

    final snackBar = ScaffoldMessenger.of(context);
    try {
      await _registrationService.registerDog(
        ownerFirstName: _ownerFirstNameController.text.trim(),
        ownerLastName: _ownerLastNameController.text.trim(),
        ownerPhone: _ownerPhoneController.text.trim().isEmpty ? null : _ownerPhoneController.text.trim(),
        ownerEmail: _ownerEmailController.text.trim().isEmpty ? null : _ownerEmailController.text.trim(),
        ownerNationalId: _ownerNationalIdController.text.trim().isEmpty ? null : _ownerNationalIdController.text.trim(),
        ownerAddressLine1: _ownerAddressLine1Controller.text.trim().isEmpty ? null : _ownerAddressLine1Controller.text.trim(),
        ownerAddressLine2: _ownerAddressLine2Controller.text.trim().isEmpty ? null : _ownerAddressLine2Controller.text.trim(),
        ownerRegionId: _selectedRegionId,
        dogNumber: _dogNumberController.text.trim(),
        dogName: _dogNameController.text.trim().isEmpty ? null : _dogNameController.text.trim(),
        dogSex: _selectedSex,
        dogBreedId: _selectedBreedId,
        dogColor: _dogColorController.text.trim().isEmpty ? null : _dogColorController.text.trim(),
        dogDob: _dogDob,
        microchipId: _microchipController.text.trim().isEmpty ? null : _microchipController.text.trim(),
        dogNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        ownershipStartDate: _ownershipStartDate,
      );

      if (!mounted) return;
      snackBar.showSnackBar(
        const SnackBar(
          content: Text('Dog registration saved to the database.'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _submitted = true;
      });
    } catch (error) {
      if (!mounted) return;
      snackBar.showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _submitting = false;
      });
    }
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
                          if (_loadingLookups) ...[
                            const LinearProgressIndicator(),
                            const SizedBox(height: 12),
                          ],
                          if (_lookupError != null) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _lookupError!,
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          _buildSectionCard(
                            title: 'Owner details',
                            child: Column(
                              children: [
                                Flex(
                                  direction: isWide ? Axis.horizontal : Axis.vertical,
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        _ownerFirstNameController,
                                        'First name',
                                        'Legal first name',
                                      ),
                                    ),
                                    SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 12),
                                    Expanded(
                                      child: _buildTextField(
                                        _ownerLastNameController,
                                        'Last name',
                                        'Legal last name',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Flex(
                                  direction: isWide ? Axis.horizontal : Axis.vertical,
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        _ownerPhoneController,
                                        'Phone number',
                                        'Best number to reach the owner',
                                        keyboardType: TextInputType.phone,
                                        isRequired: false,
                                      ),
                                    ),
                                    SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 12),
                                    Expanded(
                                      child: _buildTextField(
                                        _ownerEmailController,
                                        'Email address',
                                        'Optional, for follow-ups',
                                        keyboardType: TextInputType.emailAddress,
                                        isRequired: false,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _buildTextField(
                                  _ownerNationalIdController,
                                  'National ID',
                                  'Optional government-issued ID',
                                  isRequired: false,
                                ),
                                const SizedBox(height: 14),
                                _buildTextField(
                                  _ownerAddressLine1Controller,
                                  'Address line 1',
                                  'Street address',
                                  isRequired: false,
                                ),
                                const SizedBox(height: 14),
                                _buildTextField(
                                  _ownerAddressLine2Controller,
                                  'Address line 2',
                                  'Apartment, suite, etc.',
                                  isRequired: false,
                                ),
                                const SizedBox(height: 14),
                                _buildDropdownField(
                                  label: 'Region',
                                  helper: 'Optional region of residence',
                                  value: _selectedRegionId,
                                  items: _regions,
                                  isRequired: false,
                                  onChanged: _loadingLookups ? null : (value) => setState(() => _selectedRegionId = value),
                                ),
                              ],
                            ),
                          ),
                          _buildSectionCard(
                            title: 'Dog details',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flex(
                                  direction: isWide ? Axis.horizontal : Axis.vertical,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        _dogNumberController,
                                        'Dog number',
                                        'Unique ID issued by the registry',
                                      ),
                                    ),
                                    SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 12),
                                    Expanded(
                                      child: _buildTextField(
                                        _dogNameController,
                                        "Dog's name",
                                        'Optional call name',
                                        isRequired: false,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _buildDropdownField(
                                  label: 'Sex',
                                  helper: 'Biological sex on record',
                                  value: _selectedSex,
                                  items: const [
                                    LookupOption(id: 'male', name: 'Male'),
                                    LookupOption(id: 'female', name: 'Female'),
                                    LookupOption(id: 'unknown', name: 'Unknown'),
                                  ],
                                  onChanged: (value) => setState(() => _selectedSex = value ?? 'unknown'),
                                ),
                                const SizedBox(height: 14),
                                _buildDropdownField(
                                  label: 'Breed',
                                  helper: 'Optional breed assignment',
                                  value: _selectedBreedId,
                                  items: _breeds,
                                  isRequired: false,
                                  onChanged: _loadingLookups ? null : (value) => setState(() => _selectedBreedId = value),
                                ),
                                const SizedBox(height: 14),
                                Flex(
                                  direction: isWide ? Axis.horizontal : Axis.vertical,
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        _dogColorController,
                                        'Color',
                                        'Primary coat color',
                                        isRequired: false,
                                      ),
                                    ),
                                    SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 12),
                                    Expanded(
                                      child: _buildDateField(
                                        label: 'Date of birth',
                                        helper: 'Optional if unknown',
                                        value: _dogDob,
                                        onSelected: (value) => setState(() => _dogDob = value),
                                        isRequired: false,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _buildTextField(
                                  _microchipController,
                                  'Microchip ID',
                                  'Optional but recommended',
                                  isRequired: false,
                                ),
                                const SizedBox(height: 14),
                                _buildTextField(
                                  _notesController,
                                  'Notes',
                                  'Health, behavior, or other registry notes',
                                  maxLines: 3,
                                  isRequired: false,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildSectionCard(
                            title: 'Ownership',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDateField(
                                  label: 'Ownership start date',
                                  helper: 'Defaults to today if left empty',
                                  value: _ownershipStartDate,
                                  onSelected: (value) => setState(() => _ownershipStartDate = value),
                                  isRequired: false,
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
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: const TextStyle(color: Colors.black87),
          helperStyle: const TextStyle(color: Colors.black54),
          floatingLabelStyle: const TextStyle(color: Colors.black87),
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
          if (validator != null) {
            return validator(value);
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String helper,
    required String? value,
    required List<LookupOption> items,
    required ValueChanged<String?>? onChanged,
    bool isRequired = true,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        value: value,
        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: const TextStyle(color: Colors.black87),
          helperStyle: const TextStyle(color: Colors.black54),
          floatingLabelStyle: const TextStyle(color: Colors.black87),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12),
          ),
        ),
        items: items
            .map(
              (option) => DropdownMenuItem<String>(
                value: option.id,
                child: Text(option.name, style: const TextStyle(color: Colors.black87)),
              ),
            )
            .toList(),
        onChanged: onChanged,
        validator: (selected) {
          if (isRequired && (selected == null || selected.isEmpty)) {
            return 'Required field';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String helper,
    required DateTime? value,
    required ValueChanged<DateTime?> onSelected,
    bool isRequired = true,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        readOnly: true,
        key: ValueKey(value),
        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: const TextStyle(color: Colors.black87),
          helperStyle: const TextStyle(color: Colors.black54),
          floatingLabelStyle: const TextStyle(color: Colors.black87),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        initialValue: value == null ? '' : _formatDate(value),
        onTap: () async {
          final now = DateTime.now();
          final initial = value ?? DateTime(now.year - 1, now.month, now.day);
          final picked = await showDatePicker(
            context: context,
            initialDate: initial,
            firstDate: DateTime(1990),
            lastDate: DateTime(now.year + 1, 12, 31),
          );
          if (picked != null) {
            onSelected(picked);
          }
        },
        validator: (selected) {
          if (isRequired && (value == null)) {
            return 'Required field';
          }
          return null;
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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
                _buildSummaryTile(
                  'Owner',
                  '${_ownerFirstNameController.text} ${_ownerLastNameController.text}'.trim(),
                  Icons.person_outline,
                ),
                _buildSummaryTile('Dog number', _dogNumberController.text, Icons.confirmation_number_outlined),
                _buildSummaryTile('Dog name', _dogNameController.text, Icons.pets_outlined),
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
