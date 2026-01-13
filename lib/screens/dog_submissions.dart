import 'package:flutter/material.dart';
import 'package:local_app_tt/screens/dog_registration.dart';
import 'package:local_app_tt/services/dog_registration_service.dart';

class DogSubmissionsScreen extends StatefulWidget {
  const DogSubmissionsScreen({super.key});

  @override
  State<DogSubmissionsScreen> createState() => _DogSubmissionsScreenState();
}

class _DogSubmissionsScreenState extends State<DogSubmissionsScreen> {
  final DogRegistrationService _registrationService = DogRegistrationService.instance;

  bool _loading = true;
  String? _error;
  List<DogSubmission> _submissions = [];

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    try {
      final submissions = await _registrationService.fetchSubmissions();
      if (!mounted) return;
      setState(() {
        _submissions = submissions;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load submissions.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submissions'),
      ),
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
          child: _loading
              ? Center(
                  child: CircularProgressIndicator(color: theme.colorScheme.primary),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending submissions',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Review status updates for each request and open submissions to edit them.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (_submissions.isEmpty)
                        Text(
                          'No submissions found yet.',
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
                ),
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(ThemeData theme, DogSubmission submission) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface,
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      'Dog Registration',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      submission.dogName?.isNotEmpty == true
                          ? submission.dogName!
                          : 'Dog #${submission.dogNumber}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
              ),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Submission ID: ${submission.dogNumber}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    DogRegistrationScreen.route(dogId: submission.id),
                  );
                },
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('View submission'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
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
      case 'approved':
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }
}
