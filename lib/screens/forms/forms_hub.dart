import 'package:flutter/material.dart';
import 'package:local_app_tt/screens/forms/form_builder.dart';
import 'package:local_app_tt/screens/forms/form_entry.dart';
import 'package:local_app_tt/screens/forms/submission_detail.dart';
import 'package:local_app_tt/services/forms_service.dart';
import 'package:local_app_tt/services/user_role_service.dart';
import 'package:local_app_tt/widgets/breadcrumbs.dart';

class FormsHubScreen extends StatefulWidget {
  final String scope;
  final String title;

  const FormsHubScreen({
    super.key,
    required this.scope,
    required this.title,
  });

  @override
  State<FormsHubScreen> createState() => _FormsHubScreenState();
}

class _FormsHubScreenState extends State<FormsHubScreen> {
  final FormsService _formsService = FormsService();
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
    return FutureBuilder<AppRole>(
      future: _roleFuture,
      builder: (context, snapshot) {
        final role = snapshot.data ?? AppRole.public;
        final isAdmin = role == AppRole.admin;
        final isInternal = widget.scope == 'internal';
        final tabCount = isAdmin ? 3 : 2;
        return DefaultTabController(
          length: tabCount,
          child: Scaffold(
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
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Breadcrumbs(
                            items: [
                              BreadcrumbItem(
                                'Home',
                                onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
                              ),
                              const BreadcrumbItem('Forms'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.title,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isInternal
                                ? 'Internal requests and operational workflows.'
                                : 'Public submissions and service requests.',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                          ),
                          const SizedBox(height: 14),
                          TabBar(
                            isScrollable: tabCount > 2,
                            tabs: [
                              const Tab(text: 'Forms'),
                              const Tab(text: 'Submissions'),
                              if (isAdmin) const Tab(text: 'Admin Builder'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _FormsList(
                            scope: widget.scope,
                            formsService: _formsService,
                            role: role,
                          ),
                          _SubmissionsList(
                            scope: widget.scope,
                            formsService: _formsService,
                            role: role,
                          ),
                          if (isAdmin)
                            _AdminPanel(
                              scope: widget.scope,
                              formsService: _formsService,
                              role: role,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FormsList extends StatefulWidget {
  final String scope;
  final FormsService formsService;
  final AppRole role;

  const _FormsList({
    required this.scope,
    required this.formsService,
    required this.role,
  });

  @override
  State<_FormsList> createState() => _FormsListState();
}

class _FormsListState extends State<_FormsList> {
  late Future<List<FormTemplate>> _formsFuture;

  @override
  void initState() {
    super.initState();
    _formsFuture = widget.formsService.fetchForms(scope: widget.scope, includeDrafts: widget.role == AppRole.admin);
  }

  void _refresh() {
    setState(() {
      _formsFuture = widget.formsService.fetchForms(scope: widget.scope, includeDrafts: widget.role == AppRole.admin);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.scope == 'internal' && widget.role == AppRole.public) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 38, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Internal forms are reserved for authorized staff.',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Reach out to an administrator to request access.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return FutureBuilder<List<FormTemplate>>(
      future: _formsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final forms = snapshot.data ?? [];
        if (forms.isEmpty) {
          return _EmptyState(
            title: 'No forms yet',
            subtitle: 'Admins can create new forms for this workspace.',
            onRefresh: _refresh,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: forms.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final form = forms[index];
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FormEntryScreen(form: form),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                      child: Icon(Icons.description_outlined, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            form.title,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            form.description,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _StatusChip(label: form.status, color: theme.colorScheme.primary),
                              if (form.regionName != null)
                                _StatusChip(label: form.regionName!, color: theme.colorScheme.secondary),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SubmissionsList extends StatefulWidget {
  final String scope;
  final FormsService formsService;
  final AppRole role;

  const _SubmissionsList({
    required this.scope,
    required this.formsService,
    required this.role,
  });

  @override
  State<_SubmissionsList> createState() => _SubmissionsListState();
}

class _SubmissionsListState extends State<_SubmissionsList> {
  late Future<List<FormSubmissionSummary>> _submissionsFuture;

  @override
  void initState() {
    super.initState();
    _submissionsFuture = widget.formsService.fetchSubmissions(scope: widget.scope);
  }

  void _refresh() {
    setState(() {
      _submissionsFuture = widget.formsService.fetchSubmissions(scope: widget.scope);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<FormSubmissionSummary>>(
      future: _submissionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final submissions = snapshot.data ?? [];
        if (submissions.isEmpty) {
          return _EmptyState(
            title: 'No submissions yet',
            subtitle: 'Your submissions will appear here once created.',
            onRefresh: _refresh,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: submissions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final submission = submissions[index];
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubmissionDetailScreen(submissionId: submission.id),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.colorScheme.secondary.withOpacity(0.12),
                      child: Icon(Icons.fact_check_outlined, color: theme.colorScheme.secondary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            submission.formTitle,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            submission.summary ?? 'Submission ${submission.id.substring(0, 6)}',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _StatusChip(label: submission.status, color: theme.colorScheme.primary),
                              if (submission.regionName != null)
                                _StatusChip(label: submission.regionName!, color: theme.colorScheme.secondary),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminPanel extends StatefulWidget {
  final String scope;
  final FormsService formsService;
  final AppRole role;

  const _AdminPanel({
    required this.scope,
    required this.formsService,
    required this.role,
  });

  @override
  State<_AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<_AdminPanel> {
  late Future<List<FormTemplate>> _templatesFuture;

  @override
  void initState() {
    super.initState();
    _templatesFuture = widget.formsService.fetchForms(scope: widget.scope, includeDrafts: true);
  }

  void _refresh() {
    setState(() {
      _templatesFuture = widget.formsService.fetchForms(scope: widget.scope, includeDrafts: true);
    });
  }

  Future<void> _openBuilder({String? editFormId}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FormBuilderScreen(
          initialScope: widget.scope,
          editFormId: editFormId,
        ),
      ),
    );
    if (changed == true) {
      _refresh();
    }
  }

  Future<void> _togglePublish(FormTemplate template) async {
    final newStatus = template.status == 'published' ? 'draft' : 'published';
    await widget.formsService.updateFormStatus(formId: template.id, status: newStatus);
    _refresh();
  }

  void _showPublishedEditWarning(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unpublish this form before editing it.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<FormTemplate>>(
      future: _templatesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final templates = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin builder',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create or update dynamic form templates. Publish to make them available.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _openBuilder,
                    icon: const Icon(Icons.add),
                    label: const Text('Create new form'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (templates.isEmpty)
              _EmptyState(
                title: 'No templates yet',
                subtitle: 'Create the first form to get started.',
                onRefresh: _refresh,
              )
            else
              ...templates.map(
                (template) => Container(
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
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                        child: Icon(Icons.build_circle_outlined, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template.title,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              template.description,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              children: [
                                _StatusChip(label: template.status, color: theme.colorScheme.primary),
                                if (template.regionName != null)
                                  _StatusChip(label: template.regionName!, color: theme.colorScheme.secondary),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            onPressed: template.status == 'published'
                                ? () => _showPublishedEditWarning(context)
                                : () => _openBuilder(editFormId: template.id),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit'),
                            style: TextButton.styleFrom(
                              foregroundColor: template.status == 'published'
                                  ? theme.disabledColor
                                  : theme.colorScheme.primary,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _togglePublish(template),
                            child: Text(template.status == 'published' ? 'Unpublish' : 'Publish'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.replaceAll('_', ' '),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onRefresh;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 42, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
