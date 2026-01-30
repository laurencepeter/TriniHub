import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_app_tt/screens/dog_submissions.dart';
import 'package:local_app_tt/services/dog_registration_service.dart';
import 'package:local_app_tt/services/owner_service.dart';
import 'package:local_app_tt/services/user_role_service.dart';
import 'package:local_app_tt/utils/error_mapper.dart';
import 'package:local_app_tt/widgets/responsive_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DogRegistrationScreen extends StatefulWidget {
  const DogRegistrationScreen({
    super.key,
    this.initialDogId,
    this.ownerUserId,
    this.ownerDisplayName,
    this.ownerEmail,
  });

  final String? initialDogId;
  final String? ownerUserId;
  final String? ownerDisplayName;
  final String? ownerEmail;

  static Route<void> route({
    String? dogId,
    String? ownerUserId,
    String? ownerDisplayName,
    String? ownerEmail,
  }) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, animation, secondaryAnimation) => ResponsiveScaffold(
        childBuilder: (device) => DogRegistrationScreen(
          initialDogId: dogId,
          ownerUserId: ownerUserId,
          ownerDisplayName: ownerDisplayName,
          ownerEmail: ownerEmail,
        ),
      ),
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
  String _selectedLifeStatus = 'alive';
  DateTime? _dogDob;
  DateTime? _ownershipStartDate;
  bool _lifeStatusEditable = false;

  bool _loadingLookups = true;
  String? _lookupError;
  bool _loadingSubmissions = true;
  bool _loadingSubmissionDetail = false;
  String? _submissionsError;
  bool _submitting = false;
  bool _deleting = false;
  bool _submitted = false;
  String? _submittedDogId;
  String? _editingStatus;
  bool _showLanding = false;
  List<DogSubmission> _submissions = [];

  bool get _isAssisting => widget.ownerUserId != null && widget.ownerUserId!.trim().isNotEmpty;

  String get _assistedUserLabel {
    final display = widget.ownerDisplayName?.trim();
    final email = widget.ownerEmail?.trim();
    if (display != null && display.isNotEmpty) {
      return display;
    }
    if (email != null && email.isNotEmpty) {
      return email;
    }
    if (_isAssisting) {
      return widget.ownerUserId!;
    }
    return 'yourself';
  }

  @override
  void initState() {
    super.initState();
    final providedEmail = widget.ownerEmail?.trim();
    if (providedEmail != null && providedEmail.isNotEmpty) {
      _ownerEmailController.text = providedEmail;
    } else if (!_isAssisting) {
      final currentEmail = Supabase.instance.client.auth.currentUser?.email;
      if (currentEmail != null && currentEmail.trim().isNotEmpty) {
        _ownerEmailController.text = currentEmail;
      }
    }
    _initialize();
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

  Future<void> _initialize() async {
    await _loadLookups();
    await _prefillOwnerProfile();
    await _refreshSubmissions();
    if (!mounted) return;
    if (widget.initialDogId != null) {
      await _loadSubmissionForEdit(widget.initialDogId!);
      return;
    }
    setState(() {
      _showLanding = _submissions.isNotEmpty;
    });
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

  Future<void> _prefillOwnerProfile() async {
    if (_isAssisting || widget.initialDogId != null) {
      return;
    }
    try {
      final role = await UserRoleService().fetchCurrentRole();
      if (role != AppRole.public) {
        return;
      }
      final ownerProfile = await OwnerService(Supabase.instance.client).fetchOwnerProfile();
      if (!mounted || ownerProfile == null) {
        return;
      }
      final resolvedRegionId = ownerProfile.regionId != null &&
              _regions.any((region) => region.id == ownerProfile.regionId)
          ? ownerProfile.regionId
          : null;
      setState(() {
        if (_ownerFirstNameController.text.trim().isEmpty) {
          _ownerFirstNameController.text = ownerProfile.firstName ?? '';
        }
        if (_ownerLastNameController.text.trim().isEmpty) {
          _ownerLastNameController.text = ownerProfile.lastName ?? '';
        }
        if (_ownerPhoneController.text.trim().isEmpty) {
          _ownerPhoneController.text = ownerProfile.phone ?? '';
        }
        _selectedRegionId ??= resolvedRegionId;
      });
    } catch (_) {
      // Silent fail; prefill is best-effort.
    }
  }

  Future<void> _refreshSubmissions() async {
    try {
      final submissions = _isAssisting
          ? await _registrationService.fetchSubmissionsForUser(widget.ownerUserId!)
          : await _registrationService.fetchSubmissions();
      if (!mounted) return;
      setState(() {
        _submissions = submissions;
        _loadingSubmissions = false;
        _submissionsError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingSubmissions = false;
        _submissionsError = 'Unable to load submissions.';
      });
    }
  }

  Future<void> _loadSubmissionForEdit(String dogId) async {
    setState(() {
      _loadingSubmissionDetail = true;
    });
    final snackBar = ScaffoldMessenger.of(context);
    try {
      final detail = await _registrationService.fetchSubmissionDetail(dogId);
      if (!mounted) return;
      if (detail == null) {
        snackBar.showSnackBar(
          const SnackBar(content: Text('Unable to load that submission.')),
        );
        setState(() {
          _loadingSubmissionDetail = false;
        });
        return;
      }
      _applySubmissionDetail(detail);
      setState(() {
        _showLanding = false;
        _loadingSubmissionDetail = false;
      });
    } catch (error) {
      if (!mounted) return;
      snackBar.showSnackBar(
        SnackBar(content: Text('Unable to load submission: ${error.toString()}')),
      );
      setState(() {
        _loadingSubmissionDetail = false;
      });
    }
  }

  void _applySubmissionDetail(DogSubmissionDetail detail) {
    _ownerFirstNameController.text = detail.ownerFirstName;
    _ownerLastNameController.text = detail.ownerLastName;
    _ownerPhoneController.text = detail.ownerPhone ?? '';
    _ownerEmailController.text = detail.ownerEmail ?? '';
    _ownerNationalIdController.text = detail.ownerNationalId ?? '';
    _ownerAddressLine1Controller.text = detail.ownerAddressLine1 ?? '';
    _ownerAddressLine2Controller.text = detail.ownerAddressLine2 ?? '';
    _dogNumberController.text = detail.dogNumber;
    _dogNameController.text = detail.dogName ?? '';
    _dogColorController.text = detail.dogColor ?? '';
    _microchipController.text = detail.microchipId ?? '';
    _notesController.text = detail.notes ?? '';
    setState(() {
      _selectedBreedId = detail.dogBreedId;
      _selectedRegionId = detail.ownerRegionId;
      _selectedSex = detail.dogSex;
      _selectedLifeStatus = detail.lifeStatus;
      _dogDob = detail.dogDob;
      _ownershipStartDate = detail.ownershipStartDate;
      _submittedDogId = detail.id;
      _editingStatus = detail.status;
      _submitted = false;
      _lifeStatusEditable = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
    });

    final snackBar = ScaffoldMessenger.of(context);
    try {
      final dogId = await _registrationService.registerDog(
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
        dogLifeStatus: _selectedLifeStatus,
        ownershipStartDate: _ownershipStartDate,
        existingDogId: _submittedDogId,
        ownerAuthUserId: _isAssisting ? widget.ownerUserId : null,
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
        _submittedDogId = dogId;
        _editingStatus = 'pending';
      });
      await _refreshSubmissions();
    } catch (error) {
      if (!mounted) return;
      snackBar.showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${mapSupabaseError(error)}'),
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

  Future<void> _confirmDeleteSubmission() async {
    if (_submittedDogId == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete submission?'),
        content: const Text('This keeps the submission history but marks it as deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;
    await _deleteSubmission();
  }

  Future<void> _deleteSubmission() async {
    if (_submittedDogId == null) return;
    setState(() {
      _deleting = true;
    });
    final snackBar = ScaffoldMessenger.of(context);
    try {
      await _registrationService.deleteSubmission(_submittedDogId!);
      if (!mounted) return;
      setState(() {
        _editingStatus = 'deleted';
      });
      snackBar.showSnackBar(
        const SnackBar(
          content: Text('Submission marked as deleted.'),
          backgroundColor: Colors.orange,
        ),
      );
      await _refreshSubmissions();
    } catch (error) {
      if (!mounted) return;
      snackBar.showSnackBar(
        SnackBar(
          content: Text('Unable to delete submission: ${mapSupabaseError(error)}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _deleting = false;
      });
    }
  }

  void _startNewRegistration() {
    _dogNumberController.clear();
    _dogNameController.clear();
    _dogColorController.clear();
    _microchipController.clear();
    _notesController.clear();
    setState(() {
      _submitted = false;
      _submittedDogId = null;
      _editingStatus = null;
      _selectedBreedId = null;
      _selectedSex = 'unknown';
      _selectedLifeStatus = 'alive';
      _dogDob = null;
      _ownershipStartDate = null;
      _showLanding = false;
      _lifeStatusEditable = false;
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
              child: _buildContent(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_submitted) {
      return _buildSuccessState(theme);
    }
    if (_loadingSubmissions || _loadingSubmissionDetail) {
      return _buildLoadingState(theme);
    }
    if (_showLanding) {
      return _buildLandingState(theme);
    }
    return _buildForm(theme);
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.secondary),
          const SizedBox(height: 12),
          Text(
            _isAssisting ? 'Loading submissions for $_assistedUserLabel...' : 'Loading your submissions...',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    final isDeleted = _editingStatus == 'deleted';
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
                  if (isDeleted) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.4)),
                      ),
                      child: Text(
                        'This submission is marked as deleted. You can keep it for history, but edits are disabled.',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange[900]),
                      ),
                    ),
                  ],
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
                                        isEnabled: false,
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
                                  label: 'Corporation',
                                  helper: 'Optional corporation of residence',
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
                                if (_editingStatus != null) ...[
                                  const SizedBox(height: 14),
                                  SwitchListTile.adaptive(
                                    contentPadding: EdgeInsets.zero,
                                    value: _lifeStatusEditable,
                                    onChanged: isDeleted ? null : (value) => setState(() => _lifeStatusEditable = value),
                                    title: const Text('Update life status'),
                                    subtitle: Text(
                                      _lifeStatusEditable
                                          ? 'Choose alive or deceased for this dog.'
                                          : 'Status defaults to alive. Enable to update later.',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildDropdownField(
                                    label: 'Life status',
                                    helper: _lifeStatusEditable
                                        ? 'Record whether the dog is alive or deceased'
                                        : 'Defaulted to alive for now',
                                    value: _selectedLifeStatus,
                                    items: const [
                                      LookupOption(id: 'alive', name: 'Alive'),
                                      LookupOption(id: 'deceased', name: 'Deceased'),
                                    ],
                                    onChanged: isDeleted || !_lifeStatusEditable
                                        ? null
                                        : (value) => setState(() => _selectedLifeStatus = value ?? 'alive'),
                                  ),
                                ],
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
                              onPressed: _submitting || isDeleted ? null : _submit,
                              style: FilledButton.styleFrom(
                                textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
                                backgroundColor: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          if (_submittedDogId != null) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _deleting || isDeleted ? null : _confirmDeleteSubmission,
                                icon: _deleting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.delete_outline),
                                label: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.0),
                                  child: Text('Delete submission'),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _editingStatus == null ? 'Dog Database Intake' : 'Edit dog registration',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_editingStatus != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(_editingStatus!).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusLabel(_editingStatus!),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _statusColor(_editingStatus!),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _editingStatus == null
                ? 'Capture the essentials in one modern view. Clean inputs, quick toggles, and smooth micro-interactions keep registrations fast.'
                : 'Updates to approved submissions will return to pending for review.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          if (_isAssisting) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Registering on behalf of $_assistedUserLabel',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildLandingState(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
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
                      _isAssisting
                          ? 'Manage registrations for $_assistedUserLabel'
                          : 'Manage dog registrations',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isAssisting
                          ? 'Create or update registrations on behalf of this resident. Approved edits will return to pending status.'
                          : 'Start a new submission or pick an existing registration to edit. Approved edits will return to pending status.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: _startNewRegistration,
                          icon: const Icon(Icons.add),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                            child: Text('Create new registration'),
                          ),
                        ),
                        if (!_isAssisting)
                          OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResponsiveScaffold(
                                  childBuilder: (device) => const DogSubmissionsScreen(),
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                              child: Text('View submissions'),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSubmissionList(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionList(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isAssisting ? 'Submissions for $_assistedUserLabel' : 'Your submissions',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Pending and approved dog registrations are listed below.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          if (_submissionsError != null) ...[
            const SizedBox(height: 12),
            Text(
              _submissionsError!,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          if (_submissions.isEmpty)
            Text(
              _isAssisting
                  ? 'No submissions yet for this resident. Start a new registration above.'
                  : 'No submissions yet. Start a new registration above.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            )
          else
            Column(
              children: _submissions
                  .map(
                    (submission) => _buildSubmissionCard(theme, submission),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(ThemeData theme, DogSubmission submission) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
        color: theme.colorScheme.surface,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  submission.dogName?.isNotEmpty == true
                      ? submission.dogName!
                      : 'Dog #${submission.dogNumber}',
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dog Registration • ${submission.dogNumber}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'Life status: ${_lifeStatusLabel(submission.lifeStatus)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(submission.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusLabel(submission.status),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _statusColor(submission.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _loadSubmissionForEdit(submission.id),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    const cardTextColor = Colors.black87;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: cardTextColor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: cardTextColor,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
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
    bool isEnabled = true,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        enabled: isEnabled,
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
    final fieldFill = Colors.white;
    final fieldTextColor = Colors.black87;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: fieldFill,
        style: TextStyle(fontWeight: FontWeight.w500, color: fieldTextColor),
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: TextStyle(color: fieldTextColor),
          helperStyle: const TextStyle(color: Colors.black54),
          floatingLabelStyle: TextStyle(color: fieldTextColor),
          filled: true,
          fillColor: fieldFill,
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
                child: Text(option.name, style: TextStyle(color: fieldTextColor)),
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
          final picked = await _pickDate(value);
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

  Future<DateTime?> _pickDate(DateTime? current) async {
    final now = DateTime.now();
    final initial = current ?? DateTime(now.year - 1, now.month, now.day);
    return showDialog<DateTime?>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: CalendarDatePicker(
          initialDate: initial,
          firstDate: DateTime(1990),
          lastDate: DateTime(now.year + 1, 12, 31),
          onDateChanged: (selected) => Navigator.of(context).pop(selected),
        ),
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
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Pending approval',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We logged this dog into the database with the details provided. You can still review or edit this submission.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 18),
                _buildSummaryTile(
                  'Owner',
                  '${_ownerFirstNameController.text} ${_ownerLastNameController.text}'.trim(),
                  Icons.person_outline,
                ),
                _buildSummaryTile('Dog number', _dogNumberController.text, Icons.confirmation_number_outlined),
                _buildSummaryTile('Dog name', _dogNameController.text, Icons.pets_outlined),
                _buildSummaryTile('Life status', _lifeStatusLabel(_selectedLifeStatus), Icons.favorite_outline),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: () => setState(() => _submitted = false),
                      icon: const Icon(Icons.edit),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
                        child: Text('Edit submission'),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _startNewRegistration,
                      icon: const Icon(Icons.add),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
                        child: Text('Register another dog'),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResponsiveScaffold(
                            childBuilder: (device) => const DogSubmissionsScreen(),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
                        child: Text('View submissions'),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
                        child: Text('Close'),
                      ),
                    ),
                  ],
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
      leading: Icon(icon, color: Colors.black54),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
      ),
      subtitle: Text(
        value.isEmpty ? 'Not provided' : value,
        style: const TextStyle(color: Colors.black54),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'deleted':
        return 'Deleted';
      case 'approved':
      case 'active':
        return 'Approved';
      case 'pending':
        return 'Pending approval';
      default:
        return 'In review';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'deleted':
        return Colors.grey;
      case 'approved':
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  String _lifeStatusLabel(String status) {
    switch (status) {
      case 'deceased':
        return 'Deceased';
      case 'alive':
      default:
        return 'Alive';
    }
  }
}
