import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_app_tt/screens/externalservices.dart';
import 'package:local_app_tt/screens/home.dart';
import 'package:local_app_tt/screens/internalservices.dart';
import 'package:local_app_tt/screens/issue_snap.dart';
import 'package:local_app_tt/screens/services.dart';
import 'package:local_app_tt/screens/settings.dart';
import 'package:local_app_tt/screens/user_support_hub.dart';
import 'package:local_app_tt/services/civsnap_service.dart';
import 'package:local_app_tt/services/dog_registration_service.dart';
import 'package:local_app_tt/services/user_role_service.dart';
import 'package:local_app_tt/widgets/bottom_tab_nav.dart';
import 'package:local_app_tt/widgets/breadcrumbs.dart';
import 'package:local_app_tt/widgets/admin_gate.dart';
import 'package:local_app_tt/widgets/responsive_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  void _refreshRole() {
    setState(() {
      _roleFuture = _roleService.fetchCurrentRole();
    });
  }

  void _openAdminUsers() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AdminGate(child: AdminUserManagementScreen()),
      ),
    );
  }

  void _openUserSupport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AdminGate(child: UserSupportHubScreen()),
      ),
    );
  }

  void _handleBottomNavTap(BuildContext context, int index) {
    if (index == 3) {
      return;
    }
    Widget destination;
    switch (index) {
      case 0:
        destination = ResponsiveScaffold(
          childBuilder: (device) => HomePage(device: device),
        );
        break;
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
      case 4:
        destination = ResponsiveScaffold(
          childBuilder: (device) => SettingsPage(device: device),
        );
        break;
      default:
        destination = ResponsiveScaffold(
          childBuilder: (device) => ExternalServices(),
        );
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showBottomNav = MediaQuery.of(context).size.width < 1200;
    return FutureBuilder<AppRole>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final role = snapshot.data ?? AppRole.public;
        return Scaffold(
          appBar: AppBar(
            title: const Text('CivSnap Command Centre'),
            actions: [
              IconButton(
                tooltip: 'Refresh access',
                onPressed: _refreshRole,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          drawer: role == AppRole.admin
              ? _AdminNavigationDrawer(
                  onDashboard: () => Navigator.of(context).pop(),
                  onManageUsers: _openAdminUsers,
                  onUserSupport: _openUserSupport,
                )
              : null,
          body: Container(
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
                  if (role == AppRole.admin) _AdminDashboard(onOpenUserSupport: _openUserSupport),
                  if (role == AppRole.corporation)
                    _CorporationDashboard(onOpenUserSupport: _openUserSupport),
                  if (role == AppRole.public) const _PublicDashboard(),
                ],
              ),
            ),
          ),
          bottomNavigationBar: showBottomNav
              ? BottomNavBar(
                  currentIndex: 3,
                  onTap: (index) => _handleBottomNavTap(context, index),
                )
              : null,
        );
      },
    );
  }
}

class _AdminNavigationDrawer extends StatelessWidget {
  final VoidCallback onDashboard;
  final VoidCallback onManageUsers;
  final VoidCallback onUserSupport;

  const _AdminNavigationDrawer({
    required this.onDashboard,
    required this.onManageUsers,
    required this.onUserSupport,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(),
            child: Text(
              'Admin Navigation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: onDashboard,
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts_outlined),
            title: const Text('Users'),
            subtitle: const Text('Manage access controls'),
            onTap: () {
              Navigator.of(context).pop();
              onManageUsers();
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent_outlined),
            title: const Text('User Support'),
            subtitle: const Text('View users and act on their behalf'),
            onTap: () {
              Navigator.of(context).pop();
              onUserSupport();
            },
          ),
        ],
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
  late Future<_PublicDashboardData> _dashboardFuture;
  String _query = '';
  String _statusFilter = 'all';
  Position? _position;
  bool _loadingLocation = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
    _refreshLocation();
  }

  Future<_PublicDashboardData> _loadDashboard() async {
    final results = await Future.wait([
      _service.fetchReports(limit: 120),
      _service.fetchStatusCounts(),
    ]);
    return _PublicDashboardData(
      reports: results[0] as List<CivSnapReport>,
      statusCounts: results[1] as Map<String, int>,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _dashboardFuture = _loadDashboard();
    });
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationError = 'Enable location services to sort by proximity.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _locationError = 'Location permission denied. Showing newest reports first.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      if (!mounted) {
        return;
      }
      setState(() => _position = position);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _locationError = 'Unable to read your location.');
    } finally {
      if (!mounted) {
        return;
      }
      setState(() => _loadingLocation = false);
    }
  }

  Future<void> _vote(CivSnapReport report) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to vote on community issues.')),
      );
      return;
    }
    await _service.voteForReport(report.id);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = Supabase.instance.client.auth.currentUser != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PublicHeroCard(
          isAuthenticated: isAuthenticated,
          onReport: () => Navigator.of(context).push(IssueSnapScreen.route()),
        ),
        const SizedBox(height: 16),
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
        _LocationSortNotice(
          isLoading: _loadingLocation,
          locationError: _locationError,
          hasLocation: _position != null,
          onRefresh: _refreshLocation,
        ),
        const SizedBox(height: 12),
        FutureBuilder<_PublicDashboardData>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data;
            final reports = data?.reports ?? [];
            final statusCounts = data?.statusCounts ?? {};
            final filtered = reports.where((report) {
              final matchesQuery = _query.isEmpty ||
                  report.title.toLowerCase().contains(_query.toLowerCase()) ||
                  (report.description ?? '').toLowerCase().contains(_query.toLowerCase());
              final normalizedStatus = _normalizeStatus(report.status);
              final matchesStatus = _statusFilter == 'all' || normalizedStatus == _statusFilter;
              return matchesQuery && matchesStatus;
            }).toList();
            final sortedReports = _sortReportsByDistance(filtered, _position);
            if (filtered.isEmpty) {
              return _EmptyState(
                title: 'No matching reports',
                subtitle: 'Try adjusting your filters or submit a new report.',
                actionLabel: 'Report issue',
                onAction: () => Navigator.of(context).push(IssueSnapScreen.route()),
              );
            }
            final regionCounts = _scopeCounts(sortedReports, _ScopeKind.region);
            final corporationCounts = _scopeCounts(sortedReports, _ScopeKind.corporation);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: 'Reports by region & corporation',
                  subtitle: 'View every report grouped by operational scope.',
                ),
                const SizedBox(height: 8),
                _ScopeSummary(
                  regionCounts: regionCounts,
                  corporationCounts: corporationCounts,
                ),
                const SizedBox(height: 16),
                _ReportGrid(
                  reports: sortedReports,
                  isAuthenticated: isAuthenticated,
                  position: _position,
                  onVote: _vote,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        FutureBuilder<_PublicDashboardData>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }
            final data = snapshot.data;
            if (data == null) {
              return const SizedBox.shrink();
            }
            final totalVotes = data.reports.fold<int>(0, (sum, report) => sum + report.voteCount);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: 'Community Pulse',
                  subtitle: 'A visual snapshot of reported issues and resident engagement.',
                ),
                const SizedBox(height: 12),
                _InsightGrid(
                  totalReports: data.reports.length,
                  totalVotes: totalVotes,
                  statusCounts: data.statusCounts,
                ),
                const SizedBox(height: 12),
                _StatusDistributionBar(counts: data.statusCounts),
              ],
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

class _PublicDashboardData {
  final List<CivSnapReport> reports;
  final Map<String, int> statusCounts;

  const _PublicDashboardData({
    required this.reports,
    required this.statusCounts,
  });
}

class _PublicHeroCard extends StatelessWidget {
  final bool isAuthenticated;
  final VoidCallback onReport;

  const _PublicHeroCard({
    required this.isAuthenticated,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = LinearGradient(
      colors: [
        theme.colorScheme.primary.withOpacity(0.9),
        theme.colorScheme.secondary.withOpacity(0.85),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.public, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Community Command View',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'See every publicly logged issue, rally support, and vote to elevate what matters.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroChip(
                icon: Icons.how_to_vote_outlined,
                label: isAuthenticated ? 'Voting enabled' : 'Sign in to vote',
              ),
              const _HeroChip(
                icon: Icons.visibility_outlined,
                label: 'Live public issue feed',
              ),
              const _HeroChip(
                icon: Icons.bolt_outlined,
                label: 'Updates in real time',
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: theme.colorScheme.primary,
            ),
            onPressed: onReport,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Log a new issue'),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _InsightGrid extends StatelessWidget {
  final int totalReports;
  final int totalVotes;
  final Map<String, int> statusCounts;

  const _InsightGrid({
    required this.totalReports,
    required this.totalVotes,
    required this.statusCounts,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = _normalizeStatusCounts(statusCounts);
    final items = [
      _InsightCardData(
        label: 'Total reports',
        value: totalReports.toString(),
        icon: Icons.description_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      _InsightCardData(
        label: 'Open + pending',
        value: (normalized['pending']! + normalized['under_review']!).toString(),
        icon: Icons.campaign_outlined,
        color: Colors.orange,
      ),
      _InsightCardData(
        label: 'In progress',
        value: normalized['in_progress']!.toString(),
        icon: Icons.build_circle_outlined,
        color: Colors.purple,
      ),
      _InsightCardData(
        label: 'Community votes',
        value: totalVotes.toString(),
        icon: Icons.thumb_up_alt_outlined,
        color: Theme.of(context).colorScheme.secondary,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 840;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return SizedBox(
              width: isWide ? (constraints.maxWidth - 36) / 4 : constraints.maxWidth,
              child: _InsightCard(item: item),
            );
          }).toList(),
        );
      },
    );
  }
}

class _InsightCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InsightCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _InsightCard extends StatelessWidget {
  final _InsightCardData item;

  const _InsightCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: item.color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 6),
                Text(
                  item.value,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDistributionBar extends StatelessWidget {
  final Map<String, int> counts;

  const _StatusDistributionBar({required this.counts});

  @override
  Widget build(BuildContext context) {
    final normalized = _normalizeStatusCounts(counts);
    final total = normalized.values.fold<int>(0, (sum, count) => sum + count);
    final safeTotal = total == 0 ? 1 : total;
    final segments = [
      _StatusSegment(status: 'pending', count: normalized['pending']!),
      _StatusSegment(status: 'under_review', count: normalized['under_review']!),
      _StatusSegment(status: 'in_progress', count: normalized['in_progress']!),
      _StatusSegment(status: 'completed', count: normalized['completed']!),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status mix',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Row(
            children: segments.map((segment) {
              final flex = (segment.count / safeTotal * 100).round().clamp(1, 100);
              return Expanded(
                flex: flex,
                child: Container(
                  height: 12,
                  color: _statusColor(segment.status),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: segments.map((segment) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _statusColor(segment.status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_statusLabel(segment.status)} · ${segment.count}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StatusSegment {
  final String status;
  final int count;

  const _StatusSegment({required this.status, required this.count});
}

class _CorporationDashboard extends StatefulWidget {
  const _CorporationDashboard({required this.onOpenUserSupport});

  final VoidCallback onOpenUserSupport;

  @override
  State<_CorporationDashboard> createState() => _CorporationDashboardState();
}

class _CorporationDashboardState extends State<_CorporationDashboard> {
  final CivSnapService _service = CivSnapService.instance;
  final UserRoleService _roleService = UserRoleService();
  final DogRegistrationService _dogService = DogRegistrationService.instance;
  late Future<List<CivSnapReport>> _reportsFuture;
  String? _regionLabel;
  String? _organization;
  bool _isContextLoading = true;
  String? _contextError;
  static const List<_InitiativeItem> _initiativeItems = [
    _InitiativeItem(
      title: 'Storm drain sweep',
      subtitle: 'Phase 2 audit across priority districts.',
      icon: Icons.water_damage_outlined,
    ),
    _InitiativeItem(
      title: 'Sidewalk lighting refresh',
      subtitle: 'Replace fixtures along five commuter corridors.',
      icon: Icons.lightbulb_outline,
    ),
    _InitiativeItem(
      title: 'Pothole sprint',
      subtitle: 'Targeted repair plan for the north loop.',
      icon: Icons.construction_outlined,
    ),
  ];
  static const List<_ScheduleItem> _scheduleItems = [
    _ScheduleItem(
      title: 'Compliance review',
      subtitle: 'Week of Oct 7 • Quarterly readiness audit.',
      icon: Icons.fact_check_outlined,
    ),
    _ScheduleItem(
      title: 'Leadership sync',
      subtitle: 'Oct 15 • Progress readout and resource planning.',
      icon: Icons.groups_outlined,
    ),
    _ScheduleItem(
      title: 'Vendor check-in',
      subtitle: 'Oct 28 • SLA review with external crews.',
      icon: Icons.handshake_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _reportsFuture = _service.fetchReports(limit: 200);
    _loadContext();
  }

  Future<void> _refresh() async {
    setState(() {
      _reportsFuture = _service.fetchReports(limit: 200);
    });
    await _loadContext();
  }

  Future<void> _loadContext() async {
    setState(() {
      _isContextLoading = true;
      _contextError = null;
    });
    try {
      final assignment = await _roleService.fetchCurrentAssignment();
      final regionLabel = await _resolveRegionLabel();
      if (!mounted) {
        return;
      }
      setState(() {
        _organization = assignment?.organization;
        _regionLabel = regionLabel;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _contextError = 'Unable to load your regional scope.';
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() => _isContextLoading = false);
    }
  }

  Future<String?> _resolveRegionLabel() async {
    final user = Supabase.instance.client.auth.currentUser;
    final rawRegionId = user?.userMetadata?['region_id'];
    final regionId = rawRegionId?.toString().trim();
    if (regionId == null || regionId.isEmpty) {
      return null;
    }
    final regions = await _dogService.fetchRegions();
    final match = regions.where((region) => region.id == regionId).toList();
    if (match.isEmpty) {
      return null;
    }
    return match.first.name;
  }

  String? get _activeRegionFilter {
    if (_regionLabel != null && _regionLabel!.trim().isNotEmpty) {
      return _regionLabel;
    }
    if (_organization != null && _organization!.trim().isNotEmpty) {
      return _organization;
    }
    return null;
  }

  List<CivSnapReport> _filterReports(List<CivSnapReport> reports) {
    final filter = _activeRegionFilter;
    if (filter == null) {
      return reports;
    }
    final normalized = filter.toLowerCase();
    return reports.where((report) {
      final location = report.locationLabel?.toLowerCase() ?? '';
      return location.contains(normalized);
    }).toList();
  }

  Map<String, int> _countsFromReports(List<CivSnapReport> reports) {
    final counts = <String, int>{};
    for (final report in reports) {
      final status = _normalizeStatus(report.status);
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return _normalizeStatusCounts(counts);
  }

  Future<void> _updateStatus(
    CivSnapReport report,
    String status, {
    String? comment,
  }) async {
    await _service.updateReportStatus(
      reportId: report.id,
      status: status,
      statusComment: comment,
    );
    await _refresh();
  }

  Future<void> _openStatusUpdateDialog(CivSnapReport report) async {
    final controller = TextEditingController(text: report.statusComment ?? '');
    var selectedStatus = _normalizeStatus(report.status);
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update report status'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: _statusOptions()
                        .where((option) => option != 'all')
                        .map((option) => DropdownMenuItem(
                              value: option,
                              child: Text(_statusLabel(option)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedStatus = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Status comment',
                      hintText: 'Add context for the status change',
                    ),
                  ),
                ],
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
      await _updateStatus(report, selectedStatus, comment: controller.text);
    }
    controller.dispose();
  }

  List<_MetricItem> _staticMetrics(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return [
      _MetricItem(
        label: 'Active contracts',
        value: '12',
        icon: Icons.assignment_outlined,
        color: colors.primary,
      ),
      _MetricItem(
        label: 'Crews in field',
        value: '38',
        icon: Icons.groups_outlined,
        color: colors.secondary,
      ),
      _MetricItem(
        label: 'Open inspections',
        value: '7',
        icon: Icons.fact_check_outlined,
        color: colors.tertiary,
      ),
      _MetricItem(
        label: 'Avg. response time',
        value: '2.6 days',
        icon: Icons.timer_outlined,
        color: colors.primaryContainer,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Corporate Snapshot',
          subtitle: 'Static performance metrics for leadership reporting.',
        ),
        const SizedBox(height: 12),
        _MetricsGrid(items: _staticMetrics(context)),
        const SizedBox(height: 20),
        const _SectionHeader(
          title: 'Priority Initiatives',
          subtitle: 'Planned workstreams and delivery focus areas.',
        ),
        const SizedBox(height: 12),
        _InitiativeList(items: _initiativeItems),
        const SizedBox(height: 20),
        const _SectionHeader(
          title: 'Scheduled Reviews',
          subtitle: 'Upcoming governance and progress checkpoints.',
        ),
        const SizedBox(height: 12),
        _ScheduleList(items: _scheduleItems),
        const SizedBox(height: 20),
        _SectionHeader(
          title: 'Live Operations Overview',
          subtitle: 'Monitor live issue volume and update work progress.',
          action: OutlinedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ),
        const SizedBox(height: 12),
        _RegionScopeNotice(
          isLoading: _isContextLoading,
          errorMessage: _contextError,
          regionLabel: _activeRegionFilter,
        ),
        const SizedBox(height: 16),
        _SectionHeader(
          title: 'User Support Hub',
          subtitle: 'View user profiles, reports, and register dogs on their behalf.',
          action: FilledButton.icon(
            onPressed: widget.onOpenUserSupport,
            icon: const Icon(Icons.support_agent_outlined),
            label: const Text('Open support hub'),
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<CivSnapReport>>(
          future: _reportsFuture,
          builder: (context, snapshot) {
            final reports = _filterReports(snapshot.data ?? []);
            return _MetricsGrid(items: _reportMetrics(context, reports));
          },
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<CivSnapReport>>(
          future: _reportsFuture,
          builder: (context, snapshot) {
            final reports = snapshot.data ?? [];
            final filtered = _filterReports(reports);
            final counts = _countsFromReports(filtered);
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
            final reports = _filterReports(snapshot.data ?? []);
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
                  trailing: OutlinedButton.icon(
                    onPressed: () => _openStatusUpdateDialog(report),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Update status'),
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
            final reports = _filterReports(snapshot.data ?? []);
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
  const _AdminDashboard({required this.onOpenUserSupport});

  final VoidCallback onOpenUserSupport;

  @override
  State<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboard> {
  final UserRoleService _roleService = UserRoleService();
  final CivSnapService _service = CivSnapService.instance;
  late Future<List<UserRoleAssignment>> _assignmentsFuture;
  late Future<Map<String, int>> _countsFuture;
  late Future<List<CivSnapReport>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _assignmentsFuture = _roleService.fetchAssignments();
    _countsFuture = _service.fetchStatusCounts();
    _reportsFuture = _service.fetchReports(limit: 120);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _assignmentsFuture = _roleService.fetchAssignments();
      _countsFuture = _service.fetchStatusCounts();
      _reportsFuture = _service.fetchReports(limit: 120);
    });
  }

  Future<void> _editAssignment(UserRoleAssignment assignment) async {
    final userIdController = TextEditingController(text: assignment.userId);
    final displayNameController = TextEditingController(text: assignment.displayName ?? '');
    final emailController = TextEditingController(text: assignment.email ?? '');
    final orgController = TextEditingController(text: assignment.organization ?? '');
    var selectedRole = assignment.role;

    try {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Edit user access'),
            content: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: userIdController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'User ID',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: displayNameController,
                        decoration: const InputDecoration(
                          labelText: 'Display name',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: orgController,
                        decoration: const InputDecoration(
                          labelText: 'Organization',
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
                child: const Text('Save changes'),
              ),
            ],
          );
        },
      );

      if (shouldSave == true) {
        await _roleService.upsertAssignment(
          userId: assignment.userId,
          role: selectedRole,
          organization: orgController.text.trim().isEmpty ? null : orgController.text.trim(),
          displayName: displayNameController.text.trim().isEmpty ? null : displayNameController.text.trim(),
          email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
        );
        await _refresh();
      }
    } finally {
      userIdController.dispose();
      displayNameController.dispose();
      emailController.dispose();
      orgController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Access Control Center',
          subtitle: 'Review user access levels and assign corporations in one workspace.',
          action: FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdminGate(child: AdminUserManagementScreen()),
                ),
              );
            },
            icon: const Icon(Icons.manage_accounts_outlined),
            label: const Text('Manage users'),
          ),
        ),
        const SizedBox(height: 12),
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
                subtitle: 'Assign access levels to unlock admin and corporation dashboards.',
              );
            }
            return _AccessSummaryPanel(
              assignments: assignments,
              onRefresh: _refresh,
              onEdit: _editAssignment,
            );
          },
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          title: 'User Support Hub',
          subtitle: 'View every user, review their reports, and take action on their behalf.',
          action: FilledButton.icon(
            onPressed: widget.onOpenUserSupport,
            icon: const Icon(Icons.support_agent_outlined),
            label: const Text('Open support hub'),
          ),
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          title: 'Issue Analytics',
          subtitle: 'Live snapshot of reported issues across the network.',
          action: OutlinedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<CivSnapReport>>(
          future: _reportsFuture,
          builder: (context, snapshot) {
            final reports = snapshot.data ?? [];
            return _MetricsGrid(items: _reportMetrics(context, reports));
          },
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
          title: 'Monthly Completion Summary',
          subtitle: 'Completion trends from reported work orders.',
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

class _AccessSummaryPanel extends StatelessWidget {
  final List<UserRoleAssignment> assignments;
  final VoidCallback onRefresh;
  final ValueChanged<UserRoleAssignment> onEdit;

  const _AccessSummaryPanel({
    required this.assignments,
    required this.onRefresh,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminCount = assignments.where((assignment) => assignment.role == AppRole.admin).length;
    final corpCount = assignments.where((assignment) => assignment.role == AppRole.corporation).length;
    final publicCount = assignments.where((assignment) => assignment.role == AppRole.public).length;
    final recent = assignments.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              label: 'Admins',
              value: adminCount.toString(),
              icon: Icons.admin_panel_settings_outlined,
              color: theme.colorScheme.primary,
            ),
            _MetricCard(
              label: 'Corporations',
              value: corpCount.toString(),
              icon: Icons.apartment_outlined,
              color: theme.colorScheme.tertiary,
            ),
            _MetricCard(
              label: 'Public users',
              value: publicCount.toString(),
              icon: Icons.public_outlined,
              color: theme.colorScheme.secondary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent access updates',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          children: recent.map((assignment) {
            return _AccessCard(
              assignment: assignment,
              onEdit: () => onEdit(assignment),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final UserRoleService _roleService = UserRoleService();
  late Future<List<UserRoleAssignment>> _assignmentsFuture;

  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _orgController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  AppRole _selectedRole = AppRole.corporation;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _assignmentsFuture = _roleService.fetchAssignments();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _orgController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _assignmentsFuture = _roleService.fetchAssignments();
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

  Future<void> _editAssignment(UserRoleAssignment assignment) async {
    final userIdController = TextEditingController(text: assignment.userId);
    final displayNameController = TextEditingController(text: assignment.displayName ?? '');
    final emailController = TextEditingController(text: assignment.email ?? '');
    final orgController = TextEditingController(text: assignment.organization ?? '');
    var selectedRole = assignment.role;

    try {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Edit user access'),
            content: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: userIdController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'User ID',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: displayNameController,
                        decoration: const InputDecoration(
                          labelText: 'Display name',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: orgController,
                        decoration: const InputDecoration(
                          labelText: 'Organization',
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
                child: const Text('Save changes'),
              ),
            ],
          );
        },
      );

      if (shouldSave == true) {
        await _roleService.upsertAssignment(
          userId: assignment.userId,
          role: selectedRole,
          organization: orgController.text.trim().isEmpty ? null : orgController.text.trim(),
          displayName: displayNameController.text.trim().isEmpty ? null : displayNameController.text.trim(),
          email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
        );
        await _refresh();
      }
    } finally {
      userIdController.dispose();
      displayNameController.dispose();
      emailController.dispose();
      orgController.dispose();
    }
  }

  Future<void> _updateRole(UserRoleAssignment assignment, AppRole role) async {
    await _roleService.upsertAssignment(
      userId: assignment.userId,
      role: role,
      organization: assignment.organization,
      displayName: assignment.displayName,
      email: assignment.email,
    );
    await _refresh();
  }

  Future<void> _deleteAssignment(UserRoleAssignment assignment) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove user access?'),
        content: const Text('This removes the access entry but keeps any submissions intact.'),
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
      await _roleService.deleteAssignment(assignment.userId);
      await _refresh();
    }
  }

  void _logIssueForUser(UserRoleAssignment assignment) {
    Navigator.of(context).push(
      IssueSnapScreen.route(
        onBehalfUserId: assignment.userId,
        onBehalfName: assignment.displayName ?? assignment.email,
      ),
    );
  }

  List<UserRoleAssignment> _applySearch(List<UserRoleAssignment> assignments) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return assignments;
    }
    return assignments.where((assignment) {
      final name = (assignment.displayName ?? '').toLowerCase();
      final email = (assignment.email ?? '').toLowerCase();
      final org = (assignment.organization ?? '').toLowerCase();
      final id = assignment.userId.toLowerCase();
      return name.contains(query) || email.contains(query) || org.contains(query) || id.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Access Manager'),
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
          _SectionHeader(
            title: 'Assign access',
            subtitle: 'Create or update roles and corporation assignments.',
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
          const SizedBox(height: 20),
          Text(
            'User directory',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by name, email, organization, or ID',
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<UserRoleAssignment>>(
            future: _assignmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final assignments = _applySearch(snapshot.data ?? []);
              if (assignments.isEmpty) {
                return const _EmptyState(
                  title: 'No matching users',
                  subtitle: 'Adjust your search or add new access assignments.',
                );
              }
              return Column(
                children: assignments.map((assignment) {
                  return _AccessManagementCard(
                    assignment: assignment,
                    onEdit: () => _editAssignment(assignment),
                    onRoleChanged: (role) => _updateRole(assignment, role),
                    onDelete: () => _deleteAssignment(assignment),
                    onLogIssue: () => _logIssueForUser(assignment),
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
  final VoidCallback onEdit;

  const _AccessCard({
    required this.assignment,
    required this.onEdit,
  });

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (assignment.updatedAt != null)
                Text(
                  _formatDate(assignment.updatedAt!),
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
                ),
              IconButton(
                onPressed: onEdit,
                tooltip: 'Edit user access',
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccessManagementCard extends StatelessWidget {
  final UserRoleAssignment assignment;
  final VoidCallback onEdit;
  final ValueChanged<AppRole> onRoleChanged;
  final VoidCallback onDelete;
  final VoidCallback onLogIssue;

  const _AccessManagementCard({
    required this.assignment,
    required this.onEdit,
    required this.onRoleChanged,
    required this.onDelete,
    required this.onLogIssue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                      assignment.organization ?? 'No corporation assigned',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                    if (assignment.email != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        assignment.email!,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AppRole>(
            value: assignment.role,
            decoration: const InputDecoration(labelText: 'Access level'),
            items: AppRole.values
                .map(
                  (role) => DropdownMenuItem(
                    value: role,
                    child: Text(role.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null && value != assignment.role) {
                onRoleChanged(value);
              }
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              OutlinedButton.icon(
                onPressed: onLogIssue,
                icon: const Icon(Icons.report_gmailerrorred_outlined),
                label: const Text('Log issue'),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove'),
              ),
            ],
          ),
          if (assignment.updatedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Updated ${_formatDate(assignment.updatedAt!)}',
              style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.16),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InitiativeItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const _InitiativeItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _InitiativeList extends StatelessWidget {
  final List<_InitiativeItem> items;

  const _InitiativeList({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: items.map((item) {
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
                radius: 18,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                child: Icon(item.icon, size: 18, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ScheduleItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ScheduleItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _ScheduleList extends StatelessWidget {
  final List<_ScheduleItem> items;

  const _ScheduleList({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: items.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Icon(item.icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final List<_MetricItem> items;

  const _MetricsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 640;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return SizedBox(
              width: isWide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
              child: _MetricCard(
                label: item.label,
                value: item.value,
                icon: item.icon,
                color: item.color,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _RegionScopeNotice extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final String? regionLabel;

  const _RegionScopeNotice({
    required this.isLoading,
    required this.errorMessage,
    required this.regionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (isLoading) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading region scope...',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      );
    }
    if (errorMessage != null) {
      return Text(
        errorMessage!,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
      );
    }
    if (regionLabel == null || regionLabel!.trim().isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No region assigned yet. Showing all reports until a region is set.',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Region scope: $regionLabel',
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
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
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search by title or description',
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<String>(
            value: statusFilter,
            decoration: InputDecoration(
              labelText: 'Status',
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
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

class _LocationSortNotice extends StatelessWidget {
  final bool isLoading;
  final String? locationError;
  final bool hasLocation;
  final VoidCallback onRefresh;

  const _LocationSortNotice({
    required this.isLoading,
    required this.locationError,
    required this.hasLocation,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = locationError ??
        (hasLocation
            ? 'Sorted by proximity to your current location.'
            : 'Enable location services to sort reports by distance.');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.near_me_outlined, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: isLoading ? null : onRefresh,
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _ScopeSummary extends StatelessWidget {
  final List<_ScopeCount> regionCounts;
  final List<_ScopeCount> corporationCounts;

  const _ScopeSummary({
    required this.regionCounts,
    required this.corporationCounts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Region coverage',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _ScopeChipRow(counts: regionCounts, emptyLabel: 'No region data yet'),
        const SizedBox(height: 12),
        Text(
          'Corporation coverage',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _ScopeChipRow(counts: corporationCounts, emptyLabel: 'No corporation data yet'),
      ],
    );
  }
}

class _ScopeChipRow extends StatelessWidget {
  final List<_ScopeCount> counts;
  final String emptyLabel;

  const _ScopeChipRow({
    required this.counts,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (counts.isEmpty) {
      return Text(
        emptyLabel,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: counts.map((entry) {
        return Chip(
          label: Text('${entry.label} · ${entry.count}'),
          backgroundColor: theme.colorScheme.surfaceVariant,
        );
      }).toList(),
    );
  }
}

class _ReportGrid extends StatelessWidget {
  final List<CivSnapReport> reports;
  final bool isAuthenticated;
  final Position? position;
  final Future<void> Function(CivSnapReport report) onVote;

  const _ReportGrid({
    required this.reports,
    required this.isAuthenticated,
    required this.position,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _reportGridColumns(constraints.maxWidth);
        final tileHeight = _reportGridTileHeight(columns);
        final imageHeight = _reportGridImageHeight(columns);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: tileHeight,
          ),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            final distanceLabel = _distanceLabel(position, report);
            return _ReportTile(
              report: report,
              imageHeight: imageHeight,
              distanceLabel: distanceLabel,
              isAuthenticated: isAuthenticated,
              onVote: isAuthenticated ? () => onVote(report) : null,
            );
          },
        );
      },
    );
  }
}

class _ReportTile extends StatelessWidget {
  final CivSnapReport report;
  final double imageHeight;
  final String? distanceLabel;
  final bool isAuthenticated;
  final VoidCallback? onVote;

  const _ReportTile({
    required this.report,
    required this.imageHeight,
    required this.distanceLabel,
    required this.isAuthenticated,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scope = _parseScope(report.locationLabel);
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 320),
      tween: Tween<double>(begin: 0.96, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: FutureBuilder<String?>(
                  future: _resolvePhotoUrl(report.photoUrl),
                  builder: (context, snapshot) {
                    final photoUrl = snapshot.data;
                    if (photoUrl == null || photoUrl.trim().isEmpty) {
                      return Container(
                        color: theme.colorScheme.surfaceVariant,
                        alignment: Alignment.center,
                        child: Icon(Icons.image_outlined, color: theme.hintColor, size: 32),
                      );
                    }
                    return Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceVariant,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: theme.hintColor,
                          size: 32,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            report.title,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _StatusPill(status: _normalizeStatus(report.status)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (report.description != null && report.description!.isNotEmpty)
                      Text(
                        report.description!,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _ScopeChip(label: scope.regionLabel, icon: Icons.map_outlined),
                        _ScopeChip(label: scope.corporationLabel, icon: Icons.apartment_outlined),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: theme.hintColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            distanceLabel ?? (report.locationLabel ?? 'Location tagged'),
                            style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatDate(report.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: onVote,
                        icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
                        label: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.2),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            isAuthenticated ? '${report.voteCount} votes' : 'Sign in to vote',
                            key: ValueKey('${report.id}-${report.voteCount}-$isAuthenticated'),
                          ),
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
    );
  }
}

class _ScopeChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ScopeChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
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
          FutureBuilder<String?>(
            future: _resolvePhotoUrl(report.photoUrl),
            builder: (context, snapshot) {
              final photoUrl = snapshot.data;
              if (photoUrl == null || photoUrl.trim().isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: theme.colorScheme.surfaceVariant,
                          alignment: Alignment.center,
                          child: Icon(Icons.image_not_supported_outlined, color: theme.hintColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
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
          if (report.statusComment != null && report.statusComment!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Status note: ${report.statusComment!.trim()}',
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

List<_MetricItem> _reportMetrics(BuildContext context, List<CivSnapReport> reports) {
  final theme = Theme.of(context);
  final total = reports.length;
  final completed = reports.where((report) => _normalizeStatus(report.status) == 'completed').length;
  final active = reports.where((report) => _normalizeStatus(report.status) != 'completed').length;
  final votes = reports.fold<int>(0, (sum, report) => sum + report.voteCount);
  return [
    _MetricItem(
      label: 'Total reports',
      value: total.toString(),
      icon: Icons.description_outlined,
      color: theme.colorScheme.primary,
    ),
    _MetricItem(
      label: 'Active issues',
      value: active.toString(),
      icon: Icons.track_changes_outlined,
      color: theme.colorScheme.tertiary,
    ),
    _MetricItem(
      label: 'Completed',
      value: completed.toString(),
      icon: Icons.check_circle_outline,
      color: Colors.green,
    ),
    _MetricItem(
      label: 'Community votes',
      value: votes.toString(),
      icon: Icons.thumb_up_alt_outlined,
      color: theme.colorScheme.secondary,
    ),
  ];
}

enum _ScopeKind { region, corporation }

class _ScopeCount {
  final String label;
  final int count;

  const _ScopeCount({required this.label, required this.count});
}

class _ReportScope {
  final String regionLabel;
  final String corporationLabel;

  const _ReportScope({
    required this.regionLabel,
    required this.corporationLabel,
  });
}

List<_ScopeCount> _scopeCounts(List<CivSnapReport> reports, _ScopeKind kind) {
  final counts = <String, int>{};
  for (final report in reports) {
    final scope = _parseScope(report.locationLabel);
    final label = kind == _ScopeKind.region ? scope.regionLabel : scope.corporationLabel;
    counts[label] = (counts[label] ?? 0) + 1;
  }
  final entries = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries.map((entry) => _ScopeCount(label: entry.key, count: entry.value)).toList();
}

_ReportScope _parseScope(String? locationLabel) {
  final trimmed = locationLabel?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return const _ReportScope(regionLabel: 'Unassigned region', corporationLabel: 'Unassigned corporation');
  }
  final parts = trimmed.split(RegExp(r'\\s*[-•|/]\\s*'));
  if (parts.length >= 2) {
    return _ReportScope(regionLabel: parts.first, corporationLabel: parts[1]);
  }
  return _ReportScope(regionLabel: trimmed, corporationLabel: 'Unassigned corporation');
}

List<CivSnapReport> _sortReportsByDistance(List<CivSnapReport> reports, Position? position) {
  final sorted = List<CivSnapReport>.from(reports);
  if (position == null) {
    return sorted;
  }
  sorted.sort((a, b) {
    final distanceA = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      a.latitude,
      a.longitude,
    );
    final distanceB = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      b.latitude,
      b.longitude,
    );
    return distanceA.compareTo(distanceB);
  });
  return sorted;
}

String? _distanceLabel(Position? position, CivSnapReport report) {
  if (position == null) {
    return null;
  }
  final distanceMeters = Geolocator.distanceBetween(
    position.latitude,
    position.longitude,
    report.latitude,
    report.longitude,
  );
  if (distanceMeters < 1000) {
    return '${distanceMeters.toStringAsFixed(0)} m away';
  }
  final distanceKm = distanceMeters / 1000;
  return '${distanceKm.toStringAsFixed(1)} km away';
}

int _reportGridColumns(double width) {
  if (width >= 1400) {
    return 4;
  }
  if (width >= 1024) {
    return 3;
  }
  if (width >= 720) {
    return 2;
  }
  return 1;
}

double _reportGridTileHeight(int columns) {
  switch (columns) {
    case 4:
      return 300;
    case 3:
      return 320;
    case 2:
      return 340;
    default:
      return 360;
  }
}

double _reportGridImageHeight(int columns) {
  switch (columns) {
    case 4:
      return 120;
    case 3:
      return 130;
    case 2:
      return 150;
    default:
      return 170;
  }
}

Future<String?> _resolvePhotoUrl(String? rawUrl) async {
  if (rawUrl == null) {
    return null;
  }
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (trimmed.startsWith('http') && !trimmed.contains('/storage/v1/')) {
    return trimmed;
  }
  final storage = Supabase.instance.client.storage.from('civsnap');
  try {
    final normalized = _normalizeStoragePath(_pathFromUrl(trimmed));
    if (normalized.isEmpty) {
      return trimmed.startsWith('http') ? trimmed : null;
    }
    if (Supabase.instance.client.auth.currentUser == null) {
      return storage.getPublicUrl(normalized);
    }
    return await storage.createSignedUrl(normalized, 3600);
  } catch (_) {
    final normalized = _normalizeStoragePath(_pathFromUrl(trimmed));
    if (normalized.isEmpty) {
      return trimmed;
    }
    return storage.getPublicUrl(normalized);
  }
}

String _pathFromUrl(String url) {
  if (!url.startsWith('http')) {
    return url;
  }
  final uri = Uri.tryParse(url);
  if (uri == null) {
    return url;
  }
  return uri.path;
}

String _normalizeStoragePath(String path) {
  var normalized = path.trim();
  const publicPrefix = 'object/public/civsnap/';
  final publicIndex = normalized.indexOf(publicPrefix);
  if (publicIndex != -1) {
    return normalized.substring(publicIndex + publicPrefix.length);
  }
  const signedPrefix = 'object/sign/civsnap/';
  final signedIndex = normalized.indexOf(signedPrefix);
  if (signedIndex != -1) {
    return normalized.substring(signedIndex + signedPrefix.length);
  }
  while (normalized.startsWith('/')) {
    normalized = normalized.substring(1);
  }
  const bucketPrefix = 'civsnap/';
  if (normalized.startsWith(bucketPrefix)) {
    normalized = normalized.substring(bucketPrefix.length);
  }
  const publicBucketPrefix = 'public/civsnap/';
  if (normalized.startsWith(publicBucketPrefix)) {
    normalized = normalized.substring(publicBucketPrefix.length);
  }
  return normalized;
}
