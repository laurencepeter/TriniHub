import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:local_app_tt/services/audit_log_service.dart';

/// Severity level a reporter assigns to a bug. Mirrors the
/// `public.bug_report_severity` enum in the database.
enum BugSeverity { low, medium, high, critical }

extension BugSeverityX on BugSeverity {
  String get value {
    switch (this) {
      case BugSeverity.low:
        return 'low';
      case BugSeverity.medium:
        return 'medium';
      case BugSeverity.high:
        return 'high';
      case BugSeverity.critical:
        return 'critical';
    }
  }

  String get label {
    switch (this) {
      case BugSeverity.low:
        return 'Low';
      case BugSeverity.medium:
        return 'Medium';
      case BugSeverity.high:
        return 'High';
      case BugSeverity.critical:
        return 'Critical';
    }
  }

  static BugSeverity fromValue(String? value) {
    switch (value?.toLowerCase()) {
      case 'low':
        return BugSeverity.low;
      case 'high':
        return BugSeverity.high;
      case 'critical':
        return BugSeverity.critical;
      case 'medium':
      default:
        return BugSeverity.medium;
    }
  }
}

/// Lifecycle of a bug report. Mirrors `public.bug_report_status`.
enum BugStatus { open, triaged, inProgress, resolved, closed }

extension BugStatusX on BugStatus {
  String get value {
    switch (this) {
      case BugStatus.open:
        return 'open';
      case BugStatus.triaged:
        return 'triaged';
      case BugStatus.inProgress:
        return 'in_progress';
      case BugStatus.resolved:
        return 'resolved';
      case BugStatus.closed:
        return 'closed';
    }
  }

  String get label {
    switch (this) {
      case BugStatus.open:
        return 'Logged';
      case BugStatus.triaged:
        return 'Triaged';
      case BugStatus.inProgress:
        return 'Fix in progress';
      case BugStatus.resolved:
        return 'Resolved';
      case BugStatus.closed:
        return 'Closed';
    }
  }

  static BugStatus fromValue(String? value) {
    switch (value?.toLowerCase()) {
      case 'triaged':
        return BugStatus.triaged;
      case 'in_progress':
        return BugStatus.inProgress;
      case 'resolved':
        return BugStatus.resolved;
      case 'closed':
        return BugStatus.closed;
      case 'open':
      default:
        return BugStatus.open;
    }
  }
}

class BugReport {
  final String id;
  final String scope;
  final String title;
  final String? description;
  final String? module;
  final BugSeverity severity;
  final BugStatus status;
  final String? reporterId;
  final String? reporterEmail;
  final String? contactEmail;
  final String? platform;
  final String? appVersion;
  final DateTime createdAt;

  const BugReport({
    required this.id,
    required this.scope,
    required this.title,
    required this.severity,
    required this.status,
    required this.createdAt,
    this.description,
    this.module,
    this.reporterId,
    this.reporterEmail,
    this.contactEmail,
    this.platform,
    this.appVersion,
  });

  factory BugReport.fromJson(Map<String, dynamic> json) {
    return BugReport(
      id: json['id'].toString(),
      scope: (json['scope'] ?? 'external').toString(),
      title: (json['title'] ?? '').toString(),
      description: json['description'] as String?,
      module: json['module'] as String?,
      severity: BugSeverityX.fromValue(json['severity'] as String?),
      status: BugStatusX.fromValue(json['status'] as String?),
      reporterId: json['reporter_id'] as String?,
      reporterEmail: json['reporter_email'] as String?,
      contactEmail: json['contact_email'] as String?,
      platform: json['platform'] as String?,
      appVersion: json['app_version'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}

/// Persists bug reports filed from the Internal/External "Report a Bug" tiles.
///
/// The submission is written to `public.bug_reports` (guarded by RLS so a user
/// can only file as themselves) and mirrored into `public.audit_logs` so the
/// platform keeps a single, queryable trail of everything that happens.
class BugReportService {
  BugReportService._();
  static final BugReportService instance = BugReportService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Best-effort, non-PII platform string for triage context. Uses
  /// [defaultTargetPlatform] rather than dart:io so it stays web-safe.
  String _platformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  /// Files a bug report. Returns the created [BugReport].
  ///
  /// [scope] must be `'internal'` or `'external'`. [module] is the module
  /// (internal) or category (external) the reporter selected.
  Future<BugReport> submit({
    required String scope,
    required String title,
    String? description,
    String? module,
    BugSeverity severity = BugSeverity.medium,
    String? contactEmail,
    String? appVersion,
  }) async {
    final normalizedScope = scope.trim().toLowerCase() == 'internal' ? 'internal' : 'external';
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('A bug title is required.');
    }

    final user = _client.auth.currentUser;
    // Read the role from the JWT app_role claim only — never from
    // user-controlled userMetadata (see the security audit).
    final reporterRole = user?.appMetadata['role'] ?? user?.appMetadata['app_role'];

    String? clean(String? value) {
      final trimmed = value?.trim();
      return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    }

    final payload = <String, dynamic>{
      'scope': normalizedScope,
      'title': trimmedTitle,
      'description': clean(description),
      'module': clean(module),
      'severity': severity.value,
      'reporter_id': user?.id,
      'reporter_email': user?.email,
      'reporter_role': reporterRole?.toString(),
      'contact_email': clean(contactEmail),
      'app_version': clean(appVersion),
      'platform': _platformLabel(),
    }..removeWhere((_, value) => value == null);

    final inserted = await _client
        .from('bug_reports')
        .insert(payload)
        .select()
        .single();

    final report = BugReport.fromJson(inserted);

    // Mirror into the audit trail. Never let audit failure break the submit.
    await AuditLogService.instance.record(
      action: 'bug_report.created',
      entityType: 'bug_report',
      entityId: report.id,
      summary: '[$normalizedScope] ${report.title} · ${severity.label}',
      metadata: {
        'scope': normalizedScope,
        'severity': severity.value,
        if (report.module != null) 'module': report.module,
        'platform': report.platform,
      },
    );

    return report;
  }

  /// Reports visible to the caller. RLS returns the caller's own reports, or
  /// every report when the caller is an admin.
  Future<List<BugReport>> fetchReports({
    String? scope,
    int limit = 200,
  }) async {
    var query = _client.from('bug_reports').select();
    if (scope != null && scope.isNotEmpty) {
      query = query.eq('scope', scope);
    }
    final response = await query.order('created_at', ascending: false).limit(limit);
    if (response is! List) return [];
    return response
        .whereType<Map<String, dynamic>>()
        .map(BugReport.fromJson)
        .toList();
  }
}
