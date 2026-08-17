import 'package:supabase_flutter/supabase_flutter.dart';

class AuditLogEntry {
  final String id;
  final String? actorId;
  final String? actorEmail;
  final String? actorRole;
  final String action;
  final String? entityType;
  final String? entityId;
  final String? summary;
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? beforeData;
  final Map<String, dynamic>? afterData;
  final DateTime createdAt;

  const AuditLogEntry({
    required this.id,
    required this.action,
    required this.createdAt,
    this.actorId,
    this.actorEmail,
    this.actorRole,
    this.entityType,
    this.entityId,
    this.summary,
    this.metadata,
    this.beforeData,
    this.afterData,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] as String,
      actorId: json['actor_id'] as String?,
      actorEmail: json['actor_email'] as String?,
      actorRole: json['actor_role'] as String?,
      action: (json['action'] ?? '').toString(),
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id']?.toString(),
      summary: json['summary'] as String?,
      metadata: _mapOrNull(json['metadata']),
      beforeData: _mapOrNull(json['before_data']),
      afterData: _mapOrNull(json['after_data']),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static Map<String, dynamic>? _mapOrNull(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }
}

class AuditLogService {
  AuditLogService._();
  static final AuditLogService instance = AuditLogService._();

  SupabaseClient get _client => Supabase.instance.client;


  Future<void> record({
    required String action,
    String? entityType,
    String? entityId,
    String? summary,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? beforeData,
    Map<String, dynamic>? afterData,
  }) async {
    final user = _client.auth.currentUser;
    final payload = <String, dynamic>{
      'actor_id': user?.id,
      'actor_email': user?.email,
      // Server-controlled JWT claim only — userMetadata is user-editable and
      // could be spoofed to misattribute an action's role in the audit trail.
      'actor_role': user?.appMetadata['role'] ?? user?.appMetadata['app_role'],
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'summary': summary,
      'metadata': metadata,
      'before_data': beforeData,
      'after_data': afterData,
    }..removeWhere((_, value) => value == null);
    try {
      await _client.from('audit_logs').insert(payload);
    } catch (_) {
      // Audit logging must never break the calling flow.
    }
  }

  Future<List<AuditLogEntry>> fetchLogs({
    int limit = 200,
    String? action,
    String? entityType,
    String? actorId,
    DateTime? since,
  }) async {
    final readClient = _client;
    var query = readClient.from('audit_logs').select();
    if (action != null && action.isNotEmpty) {
      query = query.eq('action', action);
    }
    if (entityType != null && entityType.isNotEmpty) {
      query = query.eq('entity_type', entityType);
    }
    if (actorId != null && actorId.isNotEmpty) {
      query = query.eq('actor_id', actorId);
    }
    if (since != null) {
      query = query.gte('created_at', since.toIso8601String());
    }
    final response = await query.order('created_at', ascending: false).limit(limit);
    if (response is! List) return [];
    return response
        .whereType<Map<String, dynamic>>()
        .map(AuditLogEntry.fromJson)
        .toList();
  }

  Future<List<String>> fetchActions({int limit = 500}) async {
    final readClient = _client;
    final response = await readClient
        .from('audit_logs')
        .select('action')
        .order('created_at', ascending: false)
        .limit(limit);
    if (response is! List) return [];
    final set = <String>{};
    for (final row in response.whereType<Map<String, dynamic>>()) {
      final action = (row['action'] ?? '').toString();
      if (action.isNotEmpty) set.add(action);
    }
    final list = set.toList()..sort();
    return list;
  }
}
