import 'package:flutter/material.dart';
import 'package:local_app_tt/services/forms_service.dart';
import 'package:local_app_tt/services/user_role_service.dart';

class SubmissionDetailScreen extends StatefulWidget {
  final String submissionId;

  const SubmissionDetailScreen({
    super.key,
    required this.submissionId,
  });

  @override
  State<SubmissionDetailScreen> createState() => _SubmissionDetailScreenState();
}

class _SubmissionDetailScreenState extends State<SubmissionDetailScreen> {
  final FormsService _formsService = FormsService();
  final UserRoleService _roleService = UserRoleService();
  late Future<FormSubmissionDetail?> _detailFuture;
  late Future<AppRole> _roleFuture;
  bool _updatingStatus = false;

  @override
  void initState() {
    super.initState();
    _detailFuture = _formsService.fetchSubmissionDetail(widget.submissionId);
    _roleFuture = _roleService.fetchCurrentRole();
  }

  Future<void> _updateStatus(String status) async {
    setState(() {
      _updatingStatus = true;
    });
    await _formsService.updateSubmissionStatus(submissionId: widget.submissionId, status: status);
    setState(() {
      _detailFuture = _formsService.fetchSubmissionDetail(widget.submissionId);
      _updatingStatus = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission detail'),
      ),
      body: FutureBuilder<FormSubmissionDetail?>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final submission = snapshot.data;
          if (submission == null) {
            return const Center(child: Text('Submission not found.'));
          }
          return FutureBuilder<AppRole>(
            future: _roleFuture,
            builder: (context, roleSnapshot) {
              final role = roleSnapshot.data ?? AppRole.public;
              final canUpdateStatus = role == AppRole.admin || role == AppRole.corporation;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    submission.formTitle,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  _StatusBanner(status: submission.status),
                  const SizedBox(height: 16),
                  if (canUpdateStatus)
                    _StatusSelector(
                      current: submission.status,
                      updating: _updatingStatus,
                      onChanged: _updateStatus,
                    ),
                  if (canUpdateStatus) const SizedBox(height: 16),
                  _InfoRow(label: 'Summary', value: submission.summary ?? 'None'),
                  _InfoRow(label: 'Submitted', value: submission.createdAt.toLocal().toString()),
                  if (submission.locationLabel != null)
                    _InfoRow(label: 'Location', value: submission.locationLabel!),
                  if (submission.latitude != null && submission.longitude != null)
                    _InfoRow(
                      label: 'Coordinates',
                      value: '${submission.latitude!.toStringAsFixed(4)}, ${submission.longitude!.toStringAsFixed(4)}',
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Responses',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ...submission.responses.entries.map(
                    (entry) => _ResponseTile(
                      label: entry.key,
                      value: entry.value,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String status;

  const _StatusBanner({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.timelapse, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            status.replaceAll('_', ' '),
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final String current;
  final bool updating;
  final ValueChanged<String> onChanged;

  const _StatusSelector({
    required this.current,
    required this.updating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const statuses = [
      'submitted',
      'in_review',
      'needs_info',
      'approved',
      'rejected',
      'completed',
    ];
    return DropdownButtonFormField<String>(
      value: statuses.contains(current) ? current : 'submitted',
      decoration: const InputDecoration(
        labelText: 'Update status',
        border: OutlineInputBorder(),
      ),
      items: statuses
          .map((status) => DropdownMenuItem(
                value: status,
                child: Text(status.replaceAll('_', ' ')),
              ))
          .toList(),
      onChanged: updating ? null : (value) => value == null ? null : onChanged(value),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ResponseTile extends StatelessWidget {
  final String label;
  final dynamic value;

  const _ResponseTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = value is String ? value : value.toString();
    final isUrl = displayValue.startsWith('http');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          if (isUrl)
            Text(
              displayValue,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
            )
          else
            Text(displayValue, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
