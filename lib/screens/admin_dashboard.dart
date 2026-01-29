import 'package:flutter/material.dart';
import 'package:local_app_tt/data/service_catalog.dart';
import 'package:local_app_tt/screens/civsnap_portal.dart';
import 'package:local_app_tt/screens/dog_registration.dart';
import 'package:local_app_tt/screens/internalservices.dart';
import 'package:local_app_tt/screens/externalservices.dart';
import 'package:local_app_tt/screens/user_support_hub.dart';
import 'package:local_app_tt/services/civsnap_service.dart';
import 'package:local_app_tt/services/dog_registration_service.dart';
import 'package:local_app_tt/services/user_role_service.dart';
import 'package:local_app_tt/services/user_support_service.dart';
import 'package:local_app_tt/widgets/breadcrumbs.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String device;

  const AdminDashboardScreen({super.key, required this.device});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final UserSupportService _supportService = UserSupportService();
  final CivSnapService _civsnapService = CivSnapService.instance;
  final DogRegistrationService _dogService = DogRegistrationService.instance;

  late Future<List<SupportUser>> _usersFuture;
  late Future<List<CivSnapReport>> _reportsFuture;
  late Future<List<DogSubmission>> _dogsFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _supportService.fetchUsers();
    _reportsFuture = _civsnapService.fetchAllReports();
    _dogsFuture = _dogService.fetchAllSubmissions();
  }

  Future<void> _refresh() async {
    setState(() {
      _usersFuture = _supportService.fetchUsers();
      _reportsFuture = _civsnapService.fetchAllReports();
      _dogsFuture = _dogService.fetchAllSubmissions();
    });
  }

  void _openUserAnalytics(List<SupportUser> users) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminUserAnalyticsScreen(users: users)),
    );
  }

  void _openReportAnalytics(List<CivSnapReport> reports) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminCivSnapAnalyticsScreen(reports: reports)),
    );
  }

  void _openDogAnalytics(List<DogSubmission> submissions) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminDogAnalyticsScreen(submissions: submissions)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              const Breadcrumbs(items: [BreadcrumbItem('Admin'), BreadcrumbItem('Dashboard')]),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                    child: Icon(Icons.admin_panel_settings_outlined, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Command Dashboard',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Summaries, oversight, and interactive service analytics.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh dashboard',
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Overview',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<SupportUser>>(
                future: _usersFuture,
                builder: (context, userSnapshot) {
                  return FutureBuilder<List<CivSnapReport>>(
                    future: _reportsFuture,
                    builder: (context, reportSnapshot) {
                      return FutureBuilder<List<DogSubmission>>(
                        future: _dogsFuture,
                        builder: (context, dogSnapshot) {
                          final users = userSnapshot.data ?? [];
                          final reports = reportSnapshot.data ?? [];
                          final dogs = dogSnapshot.data ?? [];
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _DashboardMetricCard(
                                label: 'Users',
                                value: users.length.toString(),
                                subtitle: '${_countByRole(users, AppRole.admin)} admins · ${_countByRole(users, AppRole.corporation)} corp',
                                icon: Icons.people_outline,
                                color: theme.colorScheme.primary,
                                onTap: () => _openUserAnalytics(users),
                              ),
                              _DashboardMetricCard(
                                label: 'CivSnap reports',
                                value: reports.length.toString(),
                                subtitle: '${_countReports(reports, 'pending')} pending · ${_countReports(reports, 'completed')} completed',
                                icon: Icons.report_gmailerrorred_outlined,
                                color: theme.colorScheme.tertiary,
                                onTap: () => _openReportAnalytics(reports),
                              ),
                              _DashboardMetricCard(
                                label: 'Dog registrations',
                                value: dogs.length.toString(),
                                subtitle: '${_countDogs(dogs, 'pending')} pending · ${_countDogs(dogs, 'approved')} approved',
                                icon: Icons.pets,
                                color: theme.colorScheme.secondary,
                                onTap: () => _openDogAnalytics(dogs),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Admin service views',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ServiceActionCard(
                    title: 'User Support Hub',
                    subtitle: 'Edit users, register dogs, and log issues.',
                    icon: Icons.support_agent_outlined,
                    color: theme.colorScheme.primary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UserSupportHubScreen()),
                    ),
                  ),
                  _ServiceActionCard(
                    title: 'CivSnap Command Centre',
                    subtitle: 'Review reports and update statuses.',
                    icon: Icons.dashboard_outlined,
                    color: theme.colorScheme.tertiary,
                    onTap: () => Navigator.of(context).push(CivSnapPortalScreen.route()),
                  ),
                  _ServiceActionCard(
                    title: 'Dog Registration',
                    subtitle: 'Register new dogs or update submissions.',
                    icon: Icons.pets_outlined,
                    color: theme.colorScheme.secondary,
                    onTap: () => Navigator.of(context).push(DogRegistrationScreen.route()),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Service directories',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ServiceActionCard(
                    title: 'Internal services',
                    subtitle: 'Internal workflows and admin views.',
                    icon: Icons.apartment_outlined,
                    color: theme.colorScheme.primary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => InternalServices()),
                    ),
                  ),
                  _ServiceActionCard(
                    title: 'External services',
                    subtitle: 'Public service forms and requests.',
                    icon: Icons.public_outlined,
                    color: theme.colorScheme.secondary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ExternalServices()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Quick launch',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ...internalServiceOptions.take(3).map(
                        (option) => _ServiceChip(
                          option: option,
                          onTap: () => handleInternalServiceTap(context, option),
                        ),
                      ),
                  ...externalServiceOptions.take(3).map(
                        (option) => _ServiceChip(
                          option: option,
                          onTap: () => handleExternalServiceTap(context, option),
                        ),
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int _countByRole(List<SupportUser> users, AppRole role) {
  return users.where((user) => user.role == role).length;
}

int _countReports(List<CivSnapReport> reports, String status) {
  return reports.where((report) => report.status == status).length;
}

int _countDogs(List<DogSubmission> submissions, String status) {
  return submissions.where((dog) => dog.status == status).length;
}

class _DashboardMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardMetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('View details', style: theme.textTheme.labelSmall?.copyWith(color: color)),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward, color: color, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ServiceActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.16),
              child: Icon(icon, color: color),
            ),
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
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final ServiceOption option;
  final VoidCallback onTap;

  const _ServiceChip({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(option.icon, size: 16),
      label: Text(option.label),
    );
  }
}

class AdminUserAnalyticsScreen extends StatefulWidget {
  final List<SupportUser> users;

  const AdminUserAnalyticsScreen({super.key, required this.users});

  @override
  State<AdminUserAnalyticsScreen> createState() => _AdminUserAnalyticsScreenState();
}

class _AdminUserAnalyticsScreenState extends State<AdminUserAnalyticsScreen> {
  String _groupBy = 'Role';
  String _timeframe = 'All time';
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _applyTimeframe(widget.users);
    final entries = _groupedUserEntries(theme, filtered, _groupBy);
    final directoryUsers = _applySearch(filtered);
    return Scaffold(
      appBar: AppBar(title: const Text('User analytics')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _AnalyticsHeader(
            title: 'User directory insights',
            subtitle: 'Track role distribution and organization coverage.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _groupBy,
                  decoration: const InputDecoration(labelText: 'Group by'),
                  items: const [
                    DropdownMenuItem(value: 'Role', child: Text('Role')),
                    DropdownMenuItem(value: 'Organization', child: Text('Organization')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _groupBy = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _timeframe,
                  decoration: const InputDecoration(labelText: 'Timeframe'),
                  items: const [
                    DropdownMenuItem(value: 'All time', child: Text('All time')),
                    DropdownMenuItem(value: '30 days', child: Text('Last 30 days')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _timeframe = value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ChartCard(
            title: 'User distribution',
            child: _BarChart(entries: entries),
          ),
          const SizedBox(height: 16),
          _InsightsList(
            title: 'Highlights',
            items: _userHighlights(filtered),
          ),
          const SizedBox(height: 20),
          Text(
            'User directory',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse, search, and manage registered users from the admin directory.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by name, email, organization, or role',
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          if (directoryUsers.isEmpty)
            _EmptyState(
              title: 'No users available',
              subtitle: 'Sync users from the admin directory or adjust your filters.',
            )
          else
            Column(
              children: directoryUsers
                  .map(
                    (user) => _UserDirectoryCard(
                      user: user,
                      onView: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => UserSupportDetailScreen(user: user),
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  List<SupportUser> _applyTimeframe(List<SupportUser> users) {
    if (_timeframe == '30 days') {
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      return users.where((user) => user.updatedAt != null && user.updatedAt!.isAfter(cutoff)).toList();
    }
    return users;
  }

  List<SupportUser> _applySearch(List<SupportUser> users) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return users;
    }
    return users.where((user) {
      final fields = [
        user.displayName,
        user.email,
        user.organization,
        user.role.label,
        user.regionName,
      ].whereType<String>().map((value) => value.toLowerCase());
      return fields.any((value) => value.contains(query)) || user.userId.toLowerCase().contains(query);
    }).toList();
  }
}

class _UserDirectoryCard extends StatelessWidget {
  final SupportUser user;
  final VoidCallback onView;

  const _UserDirectoryCard({required this.user, required this.onView});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : (user.email ?? 'Unnamed user');
    final subtitleParts = <String>[];
    if (user.email != null && user.displayName?.trim().isNotEmpty == true) {
      subtitleParts.add(user.email!);
    }
    if (user.organization != null && user.organization!.trim().isNotEmpty) {
      subtitleParts.add(user.organization!.trim());
    }
    if (user.regionName != null && user.regionName!.trim().isNotEmpty) {
      subtitleParts.add(user.regionName!.trim());
    }
    final subtitle = subtitleParts.isEmpty ? 'ID: ${user.userId}' : subtitleParts.join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
          child: Icon(Icons.person_outline, color: theme.colorScheme.primary),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(user.role.label, style: theme.textTheme.labelMedium),
            TextButton(
              onPressed: onView,
              child: const Text('View'),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminCivSnapAnalyticsScreen extends StatefulWidget {
  final List<CivSnapReport> reports;

  const AdminCivSnapAnalyticsScreen({super.key, required this.reports});

  @override
  State<AdminCivSnapAnalyticsScreen> createState() => _AdminCivSnapAnalyticsScreenState();
}

class _AdminCivSnapAnalyticsScreenState extends State<AdminCivSnapAnalyticsScreen> {
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _statusFilter == 'All'
        ? widget.reports
        : widget.reports.where((report) => report.status == _statusFilter).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('CivSnap analytics')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _AnalyticsHeader(
            title: 'Report health overview',
            subtitle: 'Monitor status mix and location coverage.',
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _statusFilter,
            decoration: const InputDecoration(labelText: 'Filter status'),
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All statuses')),
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'under_review', child: Text('Under review')),
              DropdownMenuItem(value: 'in_progress', child: Text('In progress')),
              DropdownMenuItem(value: 'completed', child: Text('Completed')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _statusFilter = value);
              }
            },
          ),
          const SizedBox(height: 16),
          _ChartCard(
            title: 'Status breakdown',
            child: _BarChart(entries: _reportEntries(theme, filtered)),
          ),
          const SizedBox(height: 16),
          _InsightsList(
            title: 'Top locations',
            items: _locationHighlights(filtered),
          ),
        ],
      ),
    );
  }
}

class AdminDogAnalyticsScreen extends StatefulWidget {
  final List<DogSubmission> submissions;

  const AdminDogAnalyticsScreen({super.key, required this.submissions});

  @override
  State<AdminDogAnalyticsScreen> createState() => _AdminDogAnalyticsScreenState();
}

class _AdminDogAnalyticsScreenState extends State<AdminDogAnalyticsScreen> {
  String _lifeStatus = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _lifeStatus == 'All'
        ? widget.submissions
        : widget.submissions.where((dog) => dog.lifeStatus == _lifeStatus.toLowerCase()).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Dog registration analytics')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _AnalyticsHeader(
            title: 'Dog registration insights',
            subtitle: 'Track submission statuses and life-status mix.',
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _lifeStatus,
            decoration: const InputDecoration(labelText: 'Life status'),
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All')),
              DropdownMenuItem(value: 'Alive', child: Text('Alive')),
              DropdownMenuItem(value: 'Deceased', child: Text('Deceased')),
              DropdownMenuItem(value: 'Unknown', child: Text('Unknown')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _lifeStatus = value);
              }
            },
          ),
          const SizedBox(height: 16),
          _ChartCard(
            title: 'Status breakdown',
            child: _BarChart(entries: _dogEntries(theme, filtered)),
          ),
          const SizedBox(height: 16),
          _InsightsList(
            title: 'Recent submissions',
            items: _recentDogHighlights(filtered),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _AnalyticsHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

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
          Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<_ChartEntry> entries;

  const _BarChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Text('No data available.');
    }
    final maxValue = entries.map((entry) => entry.value).fold<int>(0, (prev, value) => value > prev ? value : prev);
    return Column(
      children: entries.map((entry) {
        final ratio = maxValue == 0 ? 0.0 : entry.value / maxValue;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(entry.label, style: Theme.of(context).textTheme.bodySmall),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 10,
                    color: entry.color,
                    backgroundColor: entry.color.withOpacity(0.1),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(entry.value.toString()),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InsightsList extends StatelessWidget {
  final String title;
  final List<String> items;

  const _InsightsList({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item, style: theme.textTheme.bodySmall)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartEntry {
  final String label;
  final int value;
  final Color color;

  const _ChartEntry({required this.label, required this.value, required this.color});
}

List<_ChartEntry> _groupedUserEntries(ThemeData theme, List<SupportUser> users, String groupBy) {
  final map = <String, int>{};
  for (final user in users) {
    final key = groupBy == 'Organization'
        ? (user.organization == null || user.organization!.isEmpty ? 'Unassigned' : user.organization!)
        : user.role.label;
    map[key] = (map[key] ?? 0) + 1;
  }
  final colors = [
    theme.colorScheme.primary,
    theme.colorScheme.tertiary,
    theme.colorScheme.secondary,
    theme.colorScheme.error,
  ];
  var index = 0;
  return map.entries.map((entry) {
    final color = colors[index % colors.length];
    index += 1;
    return _ChartEntry(label: entry.key, value: entry.value, color: color);
  }).toList();
}

List<_ChartEntry> _reportEntries(ThemeData theme, List<CivSnapReport> reports) {
  final map = <String, int>{};
  for (final report in reports) {
    map[report.status] = (map[report.status] ?? 0) + 1;
  }
  final statusColor = <String, Color>{
    'pending': theme.colorScheme.primary,
    'under_review': theme.colorScheme.tertiary,
    'in_progress': theme.colorScheme.secondary,
    'completed': Colors.green,
    'open': theme.colorScheme.primary,
  };
  return map.entries.map((entry) {
    return _ChartEntry(
      label: _statusLabel(entry.key),
      value: entry.value,
      color: statusColor[entry.key] ?? theme.colorScheme.primary,
    );
  }).toList();
}

List<_ChartEntry> _dogEntries(ThemeData theme, List<DogSubmission> submissions) {
  final map = <String, int>{};
  for (final dog in submissions) {
    map[dog.status] = (map[dog.status] ?? 0) + 1;
  }
  return map.entries.map((entry) {
    return _ChartEntry(
      label: _statusLabel(entry.key),
      value: entry.value,
      color: theme.colorScheme.secondary,
    );
  }).toList();
}

List<String> _userHighlights(List<SupportUser> users) {
  if (users.isEmpty) {
    return ['No users loaded yet.'];
  }
  final adminCount = users.where((user) => user.role == AppRole.admin).length;
  final corpCount = users.where((user) => user.role == AppRole.corporation).length;
  return [
    'Total directory size: ${users.length} users.',
    'Admins: $adminCount · Corporations: $corpCount.',
  ];
}

List<String> _locationHighlights(List<CivSnapReport> reports) {
  if (reports.isEmpty) {
    return ['No reports submitted yet.'];
  }
  final map = <String, int>{};
  for (final report in reports) {
    final location = report.locationLabel ?? 'Unknown location';
    map[location] = (map[location] ?? 0) + 1;
  }
  final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return sorted.take(4).map((entry) => '${entry.key}: ${entry.value} reports').toList();
}

List<String> _recentDogHighlights(List<DogSubmission> submissions) {
  if (submissions.isEmpty) {
    return ['No dog registrations logged yet.'];
  }
  final recent = submissions.take(4).map((dog) {
    final name = dog.dogName?.isNotEmpty == true ? dog.dogName! : 'Dog #${dog.dogNumber}';
    return '$name · ${_statusLabel(dog.status)}';
  }).toList();
  return recent;
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
    case 'approved':
    case 'active':
      return 'Approved';
    case 'deleted':
      return 'Deleted';
    default:
      return 'Open';
  }
}
