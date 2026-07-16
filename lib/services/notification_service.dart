import 'package:supabase_flutter/supabase_flutter.dart';

class AppNotification {
  final String id;
  final String? recipientId;
  final String? recipientCorporationId;
  final String title;
  final String? body;
  final String category;
  final String? entityType;
  final String? entityId;
  final String? deepLink;
  final Map<String, dynamic>? metadata;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.category,
    required this.createdAt,
    this.recipientId,
    this.recipientCorporationId,
    this.body,
    this.entityType,
    this.entityId,
    this.deepLink,
    this.metadata,
    this.readAt,
  });

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      recipientId: json['recipient_id'] as String?,
      recipientCorporationId: json['recipient_corporation_id'] as String?,
      title: (json['title'] ?? '').toString(),
      body: json['body'] as String?,
      category: (json['category'] ?? 'general').toString(),
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id']?.toString(),
      deepLink: json['deep_link'] as String?,
      metadata: json['metadata'] is Map
          ? (json['metadata'] as Map).map((k, v) => MapEntry(k.toString(), v))
          : null,
      readAt: json['read_at'] == null ? null : DateTime.tryParse(json['read_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  SupabaseClient get _client => Supabase.instance.client;


  Future<void> notifyCorporation({
    required String corporationId,
    required String title,
    String? body,
    String category = 'civsnap',
    String? entityType,
    String? entityId,
    String? deepLink,
    Map<String, dynamic>? metadata,
  }) async {
    final payload = <String, dynamic>{
      'recipient_corporation_id': corporationId,
      'title': title,
      'body': body,
      'category': category,
      'entity_type': entityType,
      'entity_id': entityId,
      'deep_link': deepLink,
      'metadata': metadata,
    }..removeWhere((_, value) => value == null);
    try {
      await _client.from('notifications').insert(payload);
    } catch (_) {}
  }

  Future<void> notifyUser({
    required String userId,
    required String title,
    String? body,
    String category = 'general',
    String? entityType,
    String? entityId,
    String? deepLink,
    Map<String, dynamic>? metadata,
  }) async {
    final payload = <String, dynamic>{
      'recipient_id': userId,
      'title': title,
      'body': body,
      'category': category,
      'entity_type': entityType,
      'entity_id': entityId,
      'deep_link': deepLink,
      'metadata': metadata,
    }..removeWhere((_, value) => value == null);
    try {
      await _client.from('notifications').insert(payload);
    } catch (_) {}
  }

  Future<List<AppNotification>> fetchInbox({int limit = 100, bool unreadOnly = false}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    final readClient = _client;

    String? corporationId;
    try {
      final profile = await readClient
          .from('user_profiles')
          .select('corporation_id')
          .eq('user_id', user.id)
          .maybeSingle();
      corporationId = profile is Map<String, dynamic> ? profile['corporation_id'] as String? : null;
    } catch (_) {}

    var query = readClient.from('notifications').select();
    if (corporationId != null && corporationId.isNotEmpty) {
      query = query.or('recipient_id.eq.${user.id},recipient_corporation_id.eq.$corporationId');
    } else {
      query = query.eq('recipient_id', user.id);
    }
    if (unreadOnly) {
      query = query.isFilter('read_at', null);
    }
    final response = await query.order('created_at', ascending: false).limit(limit);
    if (response is! List) return [];
    return response
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
  }

  Future<int> fetchUnreadCount() async {
    try {
      final inbox = await fetchInbox(unreadOnly: true, limit: 50);
      return inbox.length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      await _client
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('recipient_id', user.id)
          .isFilter('read_at', null);
    } catch (_) {}
  }
}
