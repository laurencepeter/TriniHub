import 'package:flutter/material.dart';
import 'package:local_app_tt/screens/issue_snap.dart';
import 'package:local_app_tt/services/civsnap_service.dart';
import 'package:local_app_tt/services/user_role_service.dart';
import 'package:local_app_tt/widgets/breadcrumbs.dart';

class CivSnapPortalScreen extends StatefulWidget {
  const CivSnapPortalScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const CivSnapPortalScreen());
  }

  @override
  State<CivSnapPortalScreen> createState() => _CivSnapPortalScreenState();
}

class _CivSnapPortalScreenState extends State<CivSnapPortalScreen> {
  final UserRoleService _roleService = UserRoleService();
  late Future<AppRole> _roleFuture;

  @override
  void initState() {
    super.initState();
    _roleFuture = _roleService.fetchCurrentRole();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('CivSnap Command Center'),
      ),
      body: FutureBuilder<AppRole>(
        future: _roleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final role = snapshot.data ?? AppRole.public;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.12),
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
                  const Breadcrumbs(items: [BreadcrumbItem('Services'), BreadcrumbItem('CivSnap')]),
                  const SizedBox(height: 12),
                  _RoleHeader(role: role),
                  const SizedBox(height: 20),
                  if (role == AppRole.admin) const _AdminDashboard(),
                  if (role == AppRole.corporation) const _CorporationDashboard(),
                  if (role == AppRole.public) const _PublicDashboard(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoleHeader extends StatelessWidget {
  final AppRole role;

  const _RoleHeader({required this.role});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.16),
            child: Icon(_iconForRole(role), color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${role.label} View',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  _subtitleForRole(role),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForRole(AppRole role) {
    switch (role) {
      case AppRole.admin:
        return Icons.admin_panel_settings_outlined;
      case AppRole.corporation:
        return Icons.apartment_outlined;
      case AppRole.public:
        return Icons.public_outlined;
    }
  }

  String _subtitleForRole(AppRole role) {
    switch (role) {
      case AppRole.admin:
        return 'Full access to user roles, analytics, and governance controls.';
      case AppRole.corporation:
        return 'Track operations, update statuses, and review completion summaries.';
      case AppRole.public:
        return 'Browse community issues, vote on priorities, and submit new reports.';
    }
  }
}

class _PublicDashboard extends StatefulWidget {
  const _PublicDashboard();

  @override
  State<_PublicDashboard> createState() => _PublicDashboardState();
}

class _PublicDashboardState extends State<_PublicDashboard> {
  final CivSnapService _service = CivSnapService.instance;
  late Future<List<CivSnapReport>> _reportsFuture;
  String _query = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _reportsFuture = _service.fetchReports(limit: 80);
  }

  Future<void> _refresh() async {
    setState(() {
      _reportsFuture = _service.fetchReports(limit: 80);
    });
  }

  Future<void> _vote(CivSnapReport report) async {
    await _service.voteForReport(report.id);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Community Issue Feed',
          subtitle: 'Vote to raise critical issues and help prioritize response.',
          action: TextButton.icon(
            onPressed: () => Navigator.of(context).push(IssueSnapScreen.route()),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Report issue'),
          ),
        ),
        const SizedBox(height: 12),
        _SearchAndFilter(
          onQueryChanged: (value) => setState(() => _query = value),
          onStatusChanged: (value) => setState(() => _statusFilter = value),
          statusFilter: _statusFilter,
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<CivSnapReport>>(
          future: _reportsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final reports = snapshot.data ?? [];
            final filtered = reports.where((report) {
              final matchesQuery = _query.isEmpty ||
                  report.title.toLowerCase().contains(_query.toLowerCase()) ||
                  (report.description ?? '').toLowerCase().contains(_query.toLowerCase());
              final normalizedStatus = _normalizeStatus(report.status);
              final matchesStatus = _statusFilter == 'all' || normalizedStatus == _statusFilter;
              return matchesQuery && matchesStatus;
            }).toList();
            if (filtered.isEmpty) {
              return _EmptyState(
                title: 'No matching reports',
                subtitle: 'Try adjusting your filters or submit a new report.',
                actionLabel: 'Report issue',
                onAction: () => Navigator.of(context).push(IssueSnapScreen.route()),
              );
            }
            return Column(
              children: filtered.map((report) {
                return _ReportCard(
                  report: report,
                  trailing: FilledButton.icon(
                    onPressed: () => _vote(report),
                    icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
                    label: Text('${report.voteCount} votes'),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh feed'),
          ),
        ),
      ],
    );
  }
}

class _CorporationDashboard extends StatefulWidget {
  const _CorporationDashboard();

  @override
  State<_CorporationDashboard> createState() => _CorporationDashboardState();
}

class _CorporationDashboardState extends State<_CorporationDashboard> {
  final CivSnapService _service = CivSnapService.instance;
  late Future<List<CivSnapReport>> _reportsFuture;
  late Future<Map<String, int>> _countsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _service.fetchReports(limit: 120);
    _countsFuture = _service.fetchStatusCounts();
  }

  Future<void> _refresh() async {
    setState(() {
      _reportsFuture = _service.fetchReports(limit: 120);
      _countsFuture = _service.fetchStatusCounts();
    });
  }

  Future<void> _updateStatus(CivSnapReport report, String status) async {
    await _service.updateReportStatus(reportId: report.id, status: status);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Operations Overview',
          subtitle: 'Monitor live issue volume and update work progress.',
          action: OutlinedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<Map<String, int>>(
          future: _countsFuture,
          builder: (context, snapshot) {
            final counts = _normalizeStatusCounts(snapshot.data ?? {});
            return _StatusSummaryGrid(counts: counts);
          },
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          title: 'Active Reports',
          subtitle: 'Update status as crews review and resolve issues.',
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<CivSnapReport>>(
          future: _reportsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final reports = snapshot.data ?? [];
            final active = reports.where((report) => _normalizeStatus(report.status) != 'completed').toList();
            if (active.isEmpty) {
              return const _EmptyState(
                title: 'No active reports',
                subtitle: 'All reports are completed or awaiting new submissions.',
              );
            }
            return Column(
              children: active.map((report) {
                return _ReportCard(
                  report: report,
                  trailing: _StatusDropdown(
                    currentStatus: _normalizeStatus(report.status),
                    onChanged: (value) => _updateStatus(report, value),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          title: 'Monthly Completion Summary',
          subtitle: 'Completed works tracked by month.',
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<CivSnapReport>>(
          future: _reportsFuture,
          builder: (context, snapshot) {
            final reports = snapshot.data ?? [];
            final completed = reports.where((report) => _normalizeStatus(report.status) == 'completed').toList();
            final summary = _monthlySummary(completed);
            if (summary.isEmpty) {
              return const _EmptyState(
                title: 'No completed work yet',
                subtitle: 'Mark reports as completed to see monthly summaries.',
              );
            }
            return _SummaryList(items: summary);
          },
        ),
      ],
    );
  }
}

class _AdminDashboard extends StatefulWidget {
  const _AdminDashboard();

  @override
  State<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboard> {
  final UserRoleService _roleService = UserRoleService();
  final CivSnapService _service = CivSnapService.instance;
  late Future<List<UserRoleAssignment>> _assignmentsFuture;
  late Future<Map<String, int>> _countsFuture;

  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _orgController = TextEditingController();
  AppRole _selectedRole = AppRole.corporation;

  @override
  void initState() {
    super.initState();
    _assignmentsFuture = _roleService.fetchAssignments();
    _countsFuture = _service.fetchStatusCounts();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _orgController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _assignmentsFuture = _roleService.fetchAssignments();
      _countsFuture = _service.fetchStatusCounts();
    });
  }

  Future<void> _assignRole() async {
    if (_userIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a user ID to assign access.')),
      );
      return;
    }
    await _roleService.upsertAssignment(
      userId: _userIdController.text.trim(),
      role: _selectedRole,
      organization: _orgController.text.trim().isEmpty ? null : _orgController.text.trim(),
      displayName: _displayNameController.text.trim().isEmpty ? null : _displayNameController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
    );
    _userIdController.clear();
    _displayNameController.clear();
    _emailController.clear();
    _orgController.clear();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Access Control',
          subtitle: 'Assign roles and organizations to control permissions.',
          action: OutlinedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ),
        const SizedBox(height: 12),
        _AdminAccessForm(
          userIdController: _userIdController,
          displayNameController: _displayNameController,
          emailController: _emailController,
          orgController: _orgController,
          selectedRole: _selectedRole,
          onRoleChanged: (role) => setState(() => _selectedRole = role),
          onSubmit: _assignRole,
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<UserRoleAssignment>>(
          future: _assignmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final assignments = snapshot.data ?? [];
            if (assignments.isEmpty) {
              return const _EmptyState(
                title: 'No access roles assigned',
                subtitle: 'Add a user ID to grant administrator or corporation access.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: assignments.map((assignment) {
                return _AccessCard(assignment: assignment);
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          title: 'Issue Analytics',
          subtitle: 'Live snapshot of reported issues across the network.',
        ),
        const SizedBox(height: 12),
        FutureBuilder<Map<String, int>>(
          future: _countsFuture,
          builder: (context, snapshot) {
            final counts = _normalizeStatusCounts(snapshot.data ?? {});
            return _StatusSummaryGrid(counts: counts);
          },
        ),
      ],
    );
  }
}

class _AdminAccessForm extends StatelessWidget {
  final TextEditingController userIdController;
  final TextEditingController displayNameController;
  final TextEditingController emailController;
  final TextEditingController orgController;
  final AppRole selectedRole;
  final ValueChanged<AppRole> onRoleChanged;
  final VoidCallback onSubmit;

  const _AdminAccessForm({
    required this.userIdController,
    required this.displayNameController,
    required this.emailController,
    required this.orgController,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          TextField(
            controller: userIdController,
            decoration: const InputDecoration(
              labelText: 'User ID',
              hintText: 'Supabase auth user UUID',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: displayNameController,
            decoration: const InputDecoration(
              labelText: 'Display name',
              hintText: 'Optional name for quick reference',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Optional email for notifications',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: orgController,
            decoration: const InputDecoration(
              labelText: 'Organization',
              hintText: 'Corporation or team name',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AppRole>(
            value: selectedRole,
            decoration: const InputDecoration(labelText: 'Role'),
            items: AppRole.values
                .map(
                  (role) => DropdownMenuItem(
                    value: role,
                    child: Text(role.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onRoleChanged(value);
              }
            },
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text('Assign access'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  final UserRoleAssignment assignment;

  const _AccessCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
            child: Icon(Icons.badge_outlined, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.displayName ?? assignment.email ?? assignment.userId,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  assignment.organization ?? 'No organization specified',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'Role: ${assignment.role.label}',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (assignment.updatedAt != null)
            Text(
              _formatDate(assignment.updatedAt!),
              style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
            ),
        ],
      ),
    );
  }
}

class _SearchAndFilter extends StatelessWidget {
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onStatusChanged;
  final String statusFilter;

  const _SearchAndFilter({
    required this.onQueryChanged,
    required this.onStatusChanged,
    required this.statusFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: onQueryChanged,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by title or description',
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<String>(
            value: statusFilter,
            decoration: const InputDecoration(labelText: 'Status'),
            items: _statusOptions()
                .map((option) => DropdownMenuItem(value: option, child: Text(_statusLabel(option))))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onStatusChanged(value);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final CivSnapReport report;
  final Widget trailing;

  const _ReportCard({required this.report, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              _StatusPill(status: _normalizeStatus(report.status)),
            ],
          ),
          if (report.description != null && report.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              report.description!,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: theme.hintColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  report.locationLabel ?? 'Location tagged',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
              ),
              Text(
                _formatDate(report.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerRight, child: trailing),
        ],
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  final String currentStatus;
  final ValueChanged<String> onChanged;

  const _StatusDropdown({required this.currentStatus, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: currentStatus,
      items: _statusOptions()
          .where((option) => option != 'all')
          .map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(_statusLabel(option)),
            );
          })
          .toList(),
      onChanged: (value) {
        if (value != null && value != currentStatus) {
          onChanged(value);
        }
      },
    );
  }
}

class _StatusSummaryGrid extends StatelessWidget {
  final Map<String, int> counts;

  const _StatusSummaryGrid({required this.counts});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatusSummaryItem(label: 'Pending', status: 'pending', count: counts['pending'] ?? 0),
      _StatusSummaryItem(label: 'Under review', status: 'under_review', count: counts['under_review'] ?? 0),
      _StatusSummaryItem(label: 'In progress', status: 'in_progress', count: counts['in_progress'] ?? 0),
      _StatusSummaryItem(label: 'Completed', status: 'completed', count: counts['completed'] ?? 0),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 640;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return SizedBox(
              width: isWide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
              child: _StatusSummaryTile(item: item),
            );
          }).toList(),
        );
      },
    );
  }
}

class _StatusSummaryItem {
  final String label;
  final String status;
  final int count;

  const _StatusSummaryItem({
    required this.label,
    required this.status,
    required this.count,
  });
}

class _StatusSummaryTile extends StatelessWidget {
  final _StatusSummaryItem item;

  const _StatusSummaryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusPill(status: item.status),
          const SizedBox(height: 10),
          Text(
            item.label,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            '${item.count} reports',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}

class _SummaryList extends StatelessWidget {
  final Map<String, int> items;

  const _SummaryList({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = items.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return Column(
      children: entries.map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.key,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${entry.value} completed',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

String _formatDate(DateTime dateTime) {
  final month = _monthName(dateTime.month);
  return '$month ${dateTime.day}';
}

String _monthName(int month) {
  const months = [
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
  return months[(month - 1).clamp(0, 11)];
}

String _normalizeStatus(String status) {
  final lower = status.toLowerCase();
  if (lower == 'open') {
    return 'pending';
  }
  if (lower == 'under review') {
    return 'under_review';
  }
  if (lower == 'in progress') {
    return 'in_progress';
  }
  return lower;
}

Map<String, int> _normalizeStatusCounts(Map<String, int> raw) {
  final normalized = <String, int>{};
  raw.forEach((status, count) {
    final key = _normalizeStatus(status);
    normalized[key] = (normalized[key] ?? 0) + count;
  });
  normalized.putIfAbsent('pending', () => 0);
  normalized.putIfAbsent('under_review', () => 0);
  normalized.putIfAbsent('in_progress', () => 0);
  normalized.putIfAbsent('completed', () => 0);
  return normalized;
}

Map<String, int> _monthlySummary(List<CivSnapReport> reports) {
  final summary = <String, int>{};
  for (final report in reports) {
    final monthKey = '${_monthName(report.createdAt.month)} ${report.createdAt.year}';
    summary[monthKey] = (summary[monthKey] ?? 0) + 1;
  }
  return summary;
}

Color _statusColor(String status) {
  switch (status) {
    case 'pending':
      return Colors.orange;
    case 'under_review':
      return Colors.blue;
    case 'in_progress':
      return Colors.purple;
    case 'completed':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'Pending';
    case 'under_review':
      return 'Under review';
    case 'in_progress':
      return 'In progress';
    case 'completed':
      return 'Completed';
    case 'all':
      return 'All';
    default:
      return status.replaceAll('_', ' ').trim();
  }
}

List<String> _statusOptions() {
  return ['all', 'pending', 'under_review', 'in_progress', 'completed'];
}
