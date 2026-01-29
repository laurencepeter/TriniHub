import 'package:flutter/material.dart';
import 'package:local_app_tt/screens/dog_registration.dart';
import 'package:local_app_tt/screens/issue_snap.dart';
import 'package:local_app_tt/services/civsnap_service.dart';
import 'package:local_app_tt/services/dog_registration_service.dart';
import 'package:local_app_tt/services/user_role_service.dart';
import 'package:local_app_tt/services/user_support_service.dart';

class UserSupportHubScreen extends StatefulWidget {
  const UserSupportHubScreen({super.key});

  @override
  State<UserSupportHubScreen> createState() => _UserSupportHubScreenState();
}

class _UserSupportHubScreenState extends State<UserSupportHubScreen> {
  final UserSupportService _supportService = UserSupportService();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<SupportUser>> _usersFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _usersFuture = _supportService.fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _usersFuture = _supportService.fetchUsers();
    });
  }

  List<SupportUser> _applySearch(List<SupportUser> users) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return users;
    }
    return users.where((user) {
      return user.userId.toLowerCase().contains(query) ||
          (user.displayName ?? '').toLowerCase().contains(query) ||
          (user.firstName ?? '').toLowerCase().contains(query) ||
          (user.lastName ?? '').toLowerCase().contains(query) ||
          (user.email ?? '').toLowerCase().contains(query) ||
          (user.organization ?? '').toLowerCase().contains(query);
    }).toList();
  }

  void _openDetail(SupportUser user) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UserSupportDetailScreen(user: user)),
    );
  }

  void _openDogRegistration(SupportUser user) {
    Navigator.of(context).push(
      DogRegistrationScreen.route(
        ownerUserId: user.userId,
        ownerDisplayName: user.displayName,
        ownerEmail: user.email,
      ),
    );
  }

  void _openIssueSnap(SupportUser user) {
    Navigator.of(context).push(
      IssueSnapScreen.route(
        onBehalfUserId: user.userId,
        onBehalfName: user.displayName ?? user.email,
      ),
    );
  }

  Future<void> _editUser(SupportUser user) async {
    final displayNameController = TextEditingController(text: user.displayName ?? '');
    final emailController = TextEditingController(text: user.email ?? '');
    final orgController = TextEditingController(text: user.organization ?? '');
    var selectedRole = user.role;

    try {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Edit user profile'),
            content: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: displayNameController,
                        decoration: const InputDecoration(labelText: 'Display name'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: orgController,
                        decoration: const InputDecoration(labelText: 'Organization'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<AppRole>(
                        value: selectedRole,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: AppRole.values
                            .map((role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role.label),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedRole = value);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      if (shouldSave == true) {
        await _supportService.updateUser(
          userId: user.userId,
          role: selectedRole,
          displayName: displayNameController.text.trim().isEmpty ? null : displayNameController.text.trim(),
          email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
          organization: orgController.text.trim().isEmpty ? null : orgController.text.trim(),
        );
        await _refresh();
      }
    } finally {
      displayNameController.dispose();
      emailController.dispose();
      orgController.dispose();
    }
  }

  Future<void> _createUser() async {
    final displayNameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final orgController = TextEditingController();
    var selectedRole = AppRole.public;

    try {
      final shouldCreate = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Create new user'),
            content: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: displayNameController,
                        decoration: const InputDecoration(labelText: 'Display name'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: passwordController,
                        decoration: const InputDecoration(labelText: 'Temporary password'),
                        obscureText: true,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: orgController,
                        decoration: const InputDecoration(labelText: 'Organization'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<AppRole>(
                        value: selectedRole,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: AppRole.values
                            .map((role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role.label),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedRole = value);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Create'),
              ),
            ],
          );
        },
      );

      if (shouldCreate == true) {
        final email = emailController.text.trim();
        final password = passwordController.text;
        if (email.isEmpty || password.isEmpty) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email and temporary password are required.')),
          );
          return;
        }
        await _supportService.createUser(
          email: email,
          password: password,
          role: selectedRole,
          displayName: displayNameController.text.trim().isEmpty ? null : displayNameController.text.trim(),
          organization: orgController.text.trim().isEmpty ? null : orgController.text.trim(),
        );
        await _refresh();
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created and added to the directory.')),
        );
      }
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to create the user right now.')),
      );
    } finally {
      displayNameController.dispose();
      emailController.dispose();
      passwordController.dispose();
      orgController.dispose();
    }
  }

  Future<void> _deleteUser(SupportUser user) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove user access?'),
        content: const Text('This removes the user role entry but keeps any submitted data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _supportService.deleteUserRole(user.userId);
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Support Hub'),
        actions: [
          IconButton(
            tooltip: 'Create user',
            onPressed: _createUser,
            icon: const Icon(Icons.person_add_alt),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Text(
            'Assist residents and manage submissions',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Review user records, view their CivSnap reports, and register dogs on their behalf.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by name, email, organization, or user ID',
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<SupportUser>>(
            future: _usersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final users = _applySearch(snapshot.data ?? []);
              if (users.isEmpty) {
                return _EmptyState(
                  title: 'No users found',
                  subtitle: 'Try adjusting your search or add users to the directory.',
                );
              }
              return Column(
                children: users.map((user) {
                  return _UserCard(
                    user: user,
                    onView: () => _openDetail(user),
                    onRegisterDog: () => _openDogRegistration(user),
                    onLogIssue: () => _openIssueSnap(user),
                    onEdit: () => _editUser(user),
                    onDelete: () => _deleteUser(user),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class UserSupportDetailScreen extends StatefulWidget {
  final SupportUser user;

  const UserSupportDetailScreen({super.key, required this.user});

  @override
  State<UserSupportDetailScreen> createState() => _UserSupportDetailScreenState();
}

class _UserSupportDetailScreenState extends State<UserSupportDetailScreen> {
  final UserSupportService _supportService = UserSupportService();
  final DogRegistrationService _dogService = DogRegistrationService.instance;

  late Future<OwnerProfile?> _ownerFuture;
  late Future<List<CivSnapReport>> _reportsFuture;
  late Future<List<DogSubmission>> _dogsFuture;
  late Future<List<LookupOption>> _regionsFuture;

  @override
  void initState() {
    super.initState();
    _ownerFuture = _supportService.fetchOwnerProfile(widget.user.userId);
    _reportsFuture = _supportService.fetchReportsForUser(widget.user.userId);
    _dogsFuture = _dogService.fetchSubmissionsForUser(widget.user.userId);
    _regionsFuture = _dogService.fetchRegions();
  }

  Future<void> _refresh() async {
    setState(() {
      _ownerFuture = _supportService.fetchOwnerProfile(widget.user.userId);
      _reportsFuture = _supportService.fetchReportsForUser(widget.user.userId);
      _dogsFuture = _dogService.fetchSubmissionsForUser(widget.user.userId);
      _regionsFuture = _dogService.fetchRegions();
    });
  }

  void _registerDog() {
    Navigator.of(context).push(
      DogRegistrationScreen.route(
        ownerUserId: widget.user.userId,
        ownerDisplayName: widget.user.displayName,
        ownerEmail: widget.user.email,
      ),
    );
  }

  void _logIssue() {
    Navigator.of(context).push(
      IssueSnapScreen.route(
        onBehalfUserId: widget.user.userId,
        onBehalfName: widget.user.displayName ?? widget.user.email,
      ),
    );
  }

  Future<void> _editUser() async {
    final displayNameController = TextEditingController(text: widget.user.displayName ?? '');
    final emailController = TextEditingController(text: widget.user.email ?? '');
    final orgController = TextEditingController(text: widget.user.organization ?? '');
    var selectedRole = widget.user.role;

    try {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Edit user profile'),
            content: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: displayNameController,
                        decoration: const InputDecoration(labelText: 'Display name'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: orgController,
                        decoration: const InputDecoration(labelText: 'Organization'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<AppRole>(
                        value: selectedRole,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: AppRole.values
                            .map((role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role.label),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedRole = value);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      if (shouldSave == true) {
        await _supportService.updateUser(
          userId: widget.user.userId,
          role: selectedRole,
          displayName: displayNameController.text.trim().isEmpty ? null : displayNameController.text.trim(),
          email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
          organization: orgController.text.trim().isEmpty ? null : orgController.text.trim(),
        );
        await _refresh();
      }
    } finally {
      displayNameController.dispose();
      emailController.dispose();
      orgController.dispose();
    }
  }

  Future<void> _editOwnerProfile(OwnerProfile profile) async {
    final firstNameController = TextEditingController(text: profile.firstName);
    final lastNameController = TextEditingController(text: profile.lastName);
    final phoneController = TextEditingController(text: profile.phone ?? '');
    final emailController = TextEditingController(text: profile.email ?? '');
    final nationalIdController = TextEditingController(text: profile.nationalId ?? '');
    final addressLine1Controller = TextEditingController(text: profile.addressLine1 ?? '');
    final addressLine2Controller = TextEditingController(text: profile.addressLine2 ?? '');
    String? selectedRegionId = profile.regionId;
    String? errorMessage;

    try {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Edit owner profile'),
            content: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: firstNameController,
                        decoration: const InputDecoration(labelText: 'First name'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: lastNameController,
                        decoration: const InputDecoration(labelText: 'Last name'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: nationalIdController,
                        decoration: const InputDecoration(labelText: 'National ID'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: addressLine1Controller,
                        decoration: const InputDecoration(labelText: 'Address line 1'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: addressLine2Controller,
                        decoration: const InputDecoration(labelText: 'Address line 2'),
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<List<LookupOption>>(
                        future: _regionsFuture,
                        builder: (context, snapshot) {
                          final regions = snapshot.data ?? [];
                          return DropdownButtonFormField<String>(
                            value: selectedRegionId,
                            items: regions
                                .map((region) => DropdownMenuItem(
                                      value: region.id,
                                      child: Text(region.name),
                                    ))
                                .toList(),
                            onChanged: (value) => setState(() => selectedRegionId = value),
                            decoration: const InputDecoration(labelText: 'Region'),
                          );
                        },
                      ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorMessage!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final firstName = firstNameController.text.trim();
                  final lastName = lastNameController.text.trim();
                  if (firstName.isEmpty || lastName.isEmpty) {
                    setState(() => errorMessage = 'First and last name are required.');
                    return;
                  }
                  Navigator.of(context).pop(true);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      if (shouldSave == true) {
        await _supportService.updateOwnerProfile(
          userId: widget.user.userId,
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          phone: phoneController.text,
          email: emailController.text,
          nationalId: nationalIdController.text,
          addressLine1: addressLine1Controller.text,
          addressLine2: addressLine2Controller.text,
          regionId: selectedRegionId,
        );
        await _refresh();
      }
    } finally {
      firstNameController.dispose();
      lastNameController.dispose();
      phoneController.dispose();
      emailController.dispose();
      nationalIdController.dispose();
      addressLine1Controller.dispose();
      addressLine2Controller.dispose();
    }
  }

  Future<void> _deleteUser() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove user access?'),
        content: const Text('This removes the user role entry but keeps any submitted data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _supportService.deleteUserRole(widget.user.userId);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.displayName ?? widget.user.email ?? 'User Profile'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _UserOverviewCard(user: widget.user),
          const SizedBox(height: 16),
          _SupportActionsCard(
            onRegisterDog: _registerDog,
            onLogIssue: _logIssue,
            onEdit: _editUser,
            onDelete: _deleteUser,
          ),
          const SizedBox(height: 16),
          Text(
            'Owner profile',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          FutureBuilder<OwnerProfile?>(
            future: _ownerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final profile = snapshot.data;
              if (profile == null) {
                return const _EmptyState(
                  title: 'No owner record yet',
                  subtitle: 'Register a dog or add owner details to create a profile.',
                );
              }
              return _OwnerProfileCard(
                profile: profile,
                onEdit: () => _editOwnerProfile(profile),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'CivSnap reports',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<CivSnapReport>>(
            future: _reportsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final reports = snapshot.data ?? [];
              if (reports.isEmpty) {
                return const _EmptyState(
                  title: 'No reports submitted',
                  subtitle: 'This user has not reported any issues yet.',
                );
              }
              return Column(
                children: reports.map((report) => _ReportSummaryCard(report: report)).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Dog registrations',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<DogSubmission>>(
            future: _dogsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final dogs = snapshot.data ?? [];
              if (dogs.isEmpty) {
                return const _EmptyState(
                  title: 'No dog registrations',
                  subtitle: 'Register a dog for this user to begin their record.',
                );
              }
              return Column(
                children: dogs.map((dog) => _DogRegistrationCard(submission: dog)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final SupportUser user;
  final VoidCallback onView;
  final VoidCallback onRegisterDog;
  final VoidCallback onLogIssue;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onView,
    required this.onRegisterDog,
    required this.onLogIssue,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final registrationFields = [
      _MetadataRow(label: 'First name', value: user.firstName ?? ''),
      _MetadataRow(label: 'Last name', value: user.lastName ?? ''),
      _MetadataRow(label: 'Phone', value: user.phone ?? ''),
      _MetadataRow(label: 'Region', value: user.regionName ?? user.regionId ?? ''),
    ];
    final extraFields = [
      _MetadataRow(label: 'National ID', value: user.nationalId ?? ''),
      _MetadataRow(
        label: 'Address',
        value: [user.addressLine1, user.addressLine2].whereType<String>().where((item) => item.isNotEmpty).join(', '),
      ),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                child: Icon(Icons.person_outline, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? user.email ?? user.userId,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email ?? 'No email on file',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                    if (user.organization != null && user.organization!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.organization!,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ],
                ),
              ),
              _RoleChip(role: user.role),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Registration details',
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          ...registrationFields,
          ...extraFields,
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('View profile'),
              ),
              OutlinedButton.icon(
                onPressed: onLogIssue,
                icon: const Icon(Icons.report_gmailerrorred_outlined),
                label: const Text('Log issue'),
              ),
              FilledButton.icon(
                onPressed: onRegisterDog,
                icon: const Icon(Icons.pets),
                label: const Text('Register dog'),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final AppRole role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color;
    switch (role) {
      case AppRole.admin:
        color = theme.colorScheme.primary;
        break;
      case AppRole.corporation:
        color = theme.colorScheme.tertiary;
        break;
      case AppRole.public:
        color = theme.colorScheme.secondary;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role.label,
        style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _UserOverviewCard extends StatelessWidget {
  final SupportUser user;

  const _UserOverviewCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                child: Icon(Icons.badge_outlined, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? user.email ?? user.userId,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email ?? 'No email on file',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
              ),
              _RoleChip(role: user.role),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'User ID: ${user.userId}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          if (user.organization != null && user.organization!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Organization: ${user.organization!}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
          ],
        ],
      ),
    );
  }
}

class _SupportActionsCard extends StatelessWidget {
  final VoidCallback onRegisterDog;
  final VoidCallback onLogIssue;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SupportActionsCard({
    required this.onRegisterDog,
    required this.onLogIssue,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.14),
                child: Icon(Icons.support_agent, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assisted actions',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Complete registrations on behalf of this user when they need help.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onRegisterDog,
                icon: const Icon(Icons.pets),
                label: const Text('Register dog'),
              ),
              OutlinedButton.icon(
                onPressed: onLogIssue,
                icon: const Icon(Icons.report_gmailerrorred_outlined),
                label: const Text('Log issue'),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit profile'),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove access'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OwnerProfileCard extends StatelessWidget {
  final OwnerProfile profile;
  final VoidCallback? onEdit;

  const _OwnerProfileCard({required this.profile, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = '${profile.firstName} ${profile.lastName}'.trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name.isEmpty ? 'Owner profile' : name,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (onEdit != null)
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _MetadataRow(label: 'Phone', value: profile.phone ?? 'Not provided'),
          _MetadataRow(label: 'Email', value: profile.email ?? 'Not provided'),
          _MetadataRow(label: 'National ID', value: profile.nationalId ?? 'Not provided'),
          _MetadataRow(
            label: 'Address',
            value: [profile.addressLine1, profile.addressLine2].whereType<String>().where((item) => item.isNotEmpty).join(', '),
          ),
          _MetadataRow(
            label: 'Region',
            value: profile.regionName ?? profile.regionId ?? 'Not assigned',
          ),
        ],
      ),
    );
  }
}

class _ReportSummaryCard extends StatelessWidget {
  final CivSnapReport report;

  const _ReportSummaryCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(theme, report.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.title.isEmpty ? 'Untitled report' : report.title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(report.status),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (report.description != null && report.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              report.description!,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Location: ${report.locationLabel ?? 'Unknown'}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Submitted ${_formatDate(report.createdAt)} · Votes ${report.voteCount}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}

class _DogRegistrationCard extends StatelessWidget {
  final DogSubmission submission;

  const _DogRegistrationCard({required this.submission});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(theme, submission.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
            child: Icon(Icons.pets, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  submission.dogName?.isNotEmpty == true ? submission.dogName! : 'Dog #${submission.dogNumber}',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Life status: ${_lifeStatusLabel(submission.lifeStatus)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
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
              _statusLabel(submission.status),
              style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetadataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(ThemeData theme, String status) {
  switch (status) {
    case 'completed':
    case 'approved':
    case 'active':
      return Colors.green;
    case 'pending':
    case 'open':
      return theme.colorScheme.primary;
    case 'under_review':
    case 'in_progress':
      return theme.colorScheme.tertiary;
    case 'deleted':
      return Colors.redAccent;
    default:
      return theme.colorScheme.secondary;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'completed':
      return 'Completed';
    case 'approved':
    case 'active':
      return 'Approved';
    case 'pending':
      return 'Pending';
    case 'under_review':
      return 'Under review';
    case 'in_progress':
      return 'In progress';
    case 'deleted':
      return 'Deleted';
    default:
      return 'Open';
  }
}

String _lifeStatusLabel(String status) {
  switch (status) {
    case 'deceased':
      return 'Deceased';
    case 'unknown':
      return 'Unknown';
    default:
      return 'Alive';
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')} '
      '${_monthLabel(date.month)} ${date.year}';
}

String _monthLabel(int month) {
  const labels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  if (month < 1 || month > 12) {
    return '';
  }
  return labels[month - 1];
}
