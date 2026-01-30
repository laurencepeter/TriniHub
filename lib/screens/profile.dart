import 'package:flutter/material.dart';
import 'package:local_app_tt/screens/home.dart';
import 'package:local_app_tt/services/dog_registration_service.dart';
import 'package:local_app_tt/services/owner_service.dart';
import 'package:local_app_tt/utils/validators.dart';
import 'package:local_app_tt/widgets/breadcrumbs.dart';
import 'package:local_app_tt/widgets/responsive_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  final String device;

  const ProfilePage({
    super.key,
    required this.device,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  List<LookupOption> _regions = [];
  String? _selectedRegionId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final client = Supabase.instance.client;
    final ownerService = OwnerService(client);
    final registrationService = DogRegistrationService.instance;
    final email = client.auth.currentUser?.email ?? '';
    _emailController.text = email;
    try {
      final results = await Future.wait([
        ownerService.fetchOwnerProfile(),
        registrationService.fetchRegions(),
      ]);
      if (!mounted) return;
      final profile = results[0] as OwnerProfile?;
      final regions = results[1] as List<LookupOption>;
      final regionId = profile?.regionId;
      final resolvedRegionId = regionId != null && regions.any((region) => region.id == regionId) ? regionId : null;
      setState(() {
        _regions = regions;
        _firstNameController.text = profile?.firstName ?? '';
        _lastNameController.text = profile?.lastName ?? '';
        _phoneController.text = profile?.phone ?? '';
        _selectedRegionId = resolvedRegionId;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load profile details.';
      });
    }
  }

  Future<void> _saveProfile() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      setState(() => _errorMessage = 'You need to be signed in to update your profile.');
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    final snackBar = ScaffoldMessenger.of(context);
    try {
      final ownerService = OwnerService(client);
      final updated = await ownerService.upsertOwnerProfile(
        userId: user.id,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        regionId: _selectedRegionId,
      );
      if (!mounted) return;
      setState(() {
        _selectedRegionId = updated.regionId;
      });
      snackBar.showSnackBar(
        const SnackBar(content: Text('Profile details saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      snackBar.showSnackBar(
        const SnackBar(content: Text('Unable to save profile details.')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  String _displayName() {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final combined = [first, last].where((part) => part.isNotEmpty).join(' ');
    if (combined.isNotEmpty) {
      return combined;
    }
    final email = _emailController.text.trim();
    return email.isNotEmpty ? email : 'Profile';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDesktop = widget.device == 'Desktop';
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.08),
              theme.colorScheme.surface,
              theme.colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Breadcrumbs(
                items: [
                  BreadcrumbItem(
                    'Home',
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResponsiveScaffold(
                            childBuilder: (device) => HomePage(device: widget.device),
                          ),
                        ),
                      );
                    },
                  ),
                  const BreadcrumbItem('Profile'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Profile',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage your personal details and access preferences for ${widget.device}.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                        child: Icon(Icons.person, color: theme.colorScheme.primary, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayName(),
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _emailController.text.isEmpty ? 'Update your profile details below.' : _emailController.text,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.verified, color: theme.colorScheme.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.manage_accounts_outlined, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Profile details',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keep your personal and work details up to date for quicker service access.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                      const SizedBox(height: 16),
                      if (_errorMessage != null) ...[
                        Text(
                          _errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Form(
                        key: _formKey,
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _ProfileInputField(
                              width: isDesktop ? 260 : double.infinity,
                              label: 'First name',
                              controller: _firstNameController,
                              validator: (value) => Validators.requiredField(value, label: 'First name'),
                              isLoading: _isLoading,
                            ),
                            _ProfileInputField(
                              width: isDesktop ? 260 : double.infinity,
                              label: 'Last name',
                              controller: _lastNameController,
                              validator: (value) => Validators.requiredField(value, label: 'Last name'),
                              isLoading: _isLoading,
                            ),
                            _ProfileInputField(
                              width: isDesktop ? 260 : double.infinity,
                              label: 'Email address',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              enabled: false,
                              isLoading: _isLoading,
                            ),
                            _ProfileInputField(
                              width: isDesktop ? 260 : double.infinity,
                              label: 'Phone number',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              isLoading: _isLoading,
                            ),
                            SizedBox(
                              width: isDesktop ? 260 : double.infinity,
                              child: DropdownButtonFormField<String>(
                                value: _selectedRegionId,
                                items: _regions
                                    .map(
                                      (region) => DropdownMenuItem<String>(
                                        value: region.id,
                                        child: Text(region.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _isLoading ? null : (value) => setState(() => _selectedRegionId = value),
                                decoration: const InputDecoration(
                                  labelText: 'Corporation',
                                  filled: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading) ...[
                        const LinearProgressIndicator(),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : () {},
                              icon: const Icon(Icons.upload_outlined),
                              label: const Text('Upload new photo'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: (_isSaving || _isLoading) ? null : _saveProfile,
                              icon: const Icon(Icons.save_outlined),
                              label: Text(_isSaving ? 'Saving...' : 'Save changes'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.account_circle_outlined),
                        title: const Text('Account details'),
                        subtitle: const Text('View your name, role, and contact info.'),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                      const Divider(height: 24),
                      ListTile(
                        leading: const Icon(Icons.security_outlined),
                        title: const Text('Security'),
                        subtitle: const Text('Update your password and MFA settings.'),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                      const Divider(height: 24),
                      ListTile(
                        leading: const Icon(Icons.badge_outlined),
                        title: const Text('Role & access'),
                        subtitle: const Text('View assigned departments and permissions.'),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: const [
                    ListTile(
                      leading: Icon(Icons.phone_outlined),
                      title: Text('Primary contact'),
                      subtitle: Text('+1 (868) 555-0198 · jordan.fraser@trinihub.gov'),
                    ),
                    Divider(height: 24),
                    ListTile(
                      leading: Icon(Icons.location_on_outlined),
                      title: Text('Base location'),
                      subtitle: Text('Port of Spain Operations Center'),
                    ),
                    Divider(height: 24),
                    ListTile(
                      leading: Icon(Icons.emergency_outlined),
                      title: Text('Emergency contact'),
                      subtitle: Text('Sasha Fraser · +1 (868) 555-0110'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Sign-in methods',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage how you sign in to TriniHub.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.mail_outline),
                        title: const Text('Work email'),
                        subtitle: const Text('Primary · Verified'),
                        trailing: TextButton(
                          onPressed: () {},
                          child: const Text('Change'),
                        ),
                      ),
                      const Divider(height: 24),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.phone_android_outlined),
                        title: const Text('Mobile number'),
                        subtitle: const Text('MFA enabled · Last used today'),
                        trailing: TextButton(
                          onPressed: () {},
                          child: const Text('Update'),
                        ),
                      ),
                      const Divider(height: 24),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.fingerprint),
                        title: const Text('Biometric login'),
                        subtitle: const Text('Face ID enrolled on 2 devices'),
                        trailing: TextButton(
                          onPressed: () {},
                          child: const Text('Manage'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: true,
                      onChanged: (_) {},
                      secondary: const Icon(Icons.notifications_outlined),
                      title: const Text('Notifications'),
                      subtitle: const Text('Choose what updates you receive.'),
                    ),
                    const Divider(height: 24),
                    SwitchListTile(
                      value: false,
                      onChanged: (_) {},
                      secondary: const Icon(Icons.language_outlined),
                      title: const Text('Status visibility'),
                      subtitle: const Text('Let teammates see when you are online.'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: const [
                    ListTile(
                      leading: Icon(Icons.badge_outlined),
                      title: Text('Supervisor'),
                      subtitle: Text('Asha Singh · Director of Operations'),
                    ),
                    Divider(height: 24),
                    ListTile(
                      leading: Icon(Icons.groups_outlined),
                      title: Text('Team'),
                      subtitle: Text('Field Ops Alpha · 12 members'),
                    ),
                    Divider(height: 24),
                    ListTile(
                      leading: Icon(Icons.event_available_outlined),
                      title: Text('Schedule'),
                      subtitle: Text('Mon-Fri · 8:00 AM - 4:00 PM'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned departments',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DepartmentChip(label: 'Public Safety'),
                          _DepartmentChip(label: 'Licensing'),
                          _DepartmentChip(label: 'Field Operations'),
                          _DepartmentChip(label: 'Customer Care'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: const [
                    ListTile(
                      leading: Icon(Icons.devices_outlined),
                      title: Text('Registered devices'),
                      subtitle: Text('2 active devices · Last login 14 minutes ago'),
                      trailing: Icon(Icons.chevron_right),
                    ),
                    Divider(height: 24),
                    ListTile(
                      leading: Icon(Icons.shield_outlined),
                      title: Text('Security score'),
                      subtitle: Text('Strong · MFA enabled · Recovery email verified'),
                      trailing: Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.fact_check_outlined, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Profile completion',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: 0.82,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '82% complete · Add a secondary contact and verify your work email.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: const [
                    ListTile(
                      leading: Icon(Icons.history_toggle_off),
                      title: Text('Recent activity'),
                      subtitle: Text('Reviewed 12 service requests today.'),
                    ),
                    Divider(height: 24),
                    ListTile(
                      leading: Icon(Icons.schedule_outlined),
                      title: Text('Upcoming shift'),
                      subtitle: Text('Wed · 8:00 AM - 4:00 PM (Operations Center)'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepartmentChip extends StatelessWidget {
  final String label;

  const _DepartmentChip({required this.label});

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
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProfileInputField extends StatelessWidget {
  final double width;
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool isLoading;
  final String? Function(String?)? validator;

  const _ProfileInputField({
    required this.width,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.enabled = true,
    this.isLoading = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        enabled: enabled && !isLoading,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
        ),
        validator: validator,
      ),
    );
  }
}
