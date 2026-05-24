import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_app_tt/services/audit_log_service.dart';
import 'package:local_app_tt/services/boundary_service.dart';
import 'package:local_app_tt/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CivSnapReport {
  final String id;
  final String title;
  final String? description;
  final String? photoUrl;
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final String? locationLabel;
  final DateTime createdAt;
  final String status;
  final String? statusComment;
  final bool isAnonymous;
  final int voteCount;

  const CivSnapReport({
    required this.id,
    required this.title,
    required this.description,
    required this.photoUrl,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.locationLabel,
    required this.createdAt,
    required this.status,
    required this.statusComment,
    required this.isAnonymous,
    required this.voteCount,
  });

  factory CivSnapReport.fromJson(Map<String, dynamic> json) {
    return CivSnapReport(
      id: json['id'] as String,
      title: (json['title'] ?? '').toString(),
      description: json['description'] as String?,
      photoUrl: json['photo_url'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracyMeters: (json['accuracy_m'] as num?)?.toDouble(),
      locationLabel: json['location_label'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: (json['status'] ?? 'open').toString(),
      statusComment: json['status_comment'] as String?,
      isAnonymous: _parseBool(json['is_anonymous']),
      voteCount: _parseVoteCount(json['civsnap_votes']),
    );
  }

  static int _parseVoteCount(dynamic value) {
    if (value is List && value.isNotEmpty) {
      final entry = value.first;
      if (entry is Map && entry['count'] != null) {
        return (entry['count'] as num).toInt();
      }
    }
    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return false;
  }
}

bool isCivSnapVotesRelationshipMissing(Object error) {
  if (error is PostgrestException) {
    return error.message.contains("Could not find a relationship between 'civsnap_reports'") &&
        error.message.contains("'civsnap_votes'");
  }
  return false;
}

bool isCivSnapStatusCommentMissing(Object error) {
  if (error is PostgrestException) {
    return error.message.contains('status_comment') && error.message.contains('column');
  }
  return false;
}

bool isCivSnapAnonymousMissing(Object error) {
  if (error is PostgrestException) {
    return error.message.contains('is_anonymous') && error.message.contains('column');
  }
  return false;
}

class CivSnapService {
  CivSnapService._();
  static final CivSnapService instance = CivSnapService._();

  final SupabaseClient _client = Supabase.instance.client;

  SupabaseClient? _buildServiceRoleClient() {
    final url = dotenv.env['SUPABASE_URL'] ?? const String.fromEnvironment('SUPABASE_URL');
    final serviceKey = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ??
        const String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY');
    if (url.trim().isEmpty || serviceKey.trim().isEmpty) {
      return null;
    }
    return SupabaseClient(url, serviceKey);
  }

  SupabaseClient _readClient() => _buildServiceRoleClient() ?? _client;

  String _reportSelectColumns({
    required bool includeStatusComment,
    required bool includeAnonymous,
  }) {
    final columns = <String>[
      'id',
      'title',
      'description',
      'photo_url',
      'latitude',
      'longitude',
      'accuracy_m',
      'location_label',
      'status',
      if (includeStatusComment) 'status_comment',
      if (includeAnonymous) 'is_anonymous',
      'created_at',
    ];
    return columns.join(',');
  }

  String _reportSelect({
    required bool includeVotes,
    required bool includeStatusComment,
    required bool includeAnonymous,
  }) {
    final base = _reportSelectColumns(
      includeStatusComment: includeStatusComment,
      includeAnonymous: includeAnonymous,
    );
    if (!includeVotes) {
      return base;
    }
    return '$base,civsnap_votes(count)';
  }

  Future<CivSnapReport?> findNearbyReport({
    required double latitude,
    required double longitude,
    double radiusMeters = 5,
  }) async {
    final deltaLat = radiusMeters / 111111;
    final deltaLng = radiusMeters / (111111 * cos(_toRadians(latitude)));
    final readClient = _readClient();
    var includeVotes = true;
    var includeStatusComment = true;
    var includeAnonymous = true;
    List<dynamic> response;
    while (true) {
      try {
        response = await readClient
            .from('civsnap_reports')
            .select(
              _reportSelect(
                includeVotes: includeVotes,
                includeStatusComment: includeStatusComment,
                includeAnonymous: includeAnonymous,
              ),
            )
            .inFilter('status', ['open', 'pending', 'under_review', 'in_progress'])
            .gte('latitude', latitude - deltaLat)
            .lte('latitude', latitude + deltaLat)
            .gte('longitude', longitude - deltaLng)
            .lte('longitude', longitude + deltaLng)
            .order('created_at', ascending: false)
            .limit(12);
        break;
      } on PostgrestException catch (error) {
        if (includeStatusComment && isCivSnapStatusCommentMissing(error)) {
          includeStatusComment = false;
          continue;
        }
        if (includeAnonymous && isCivSnapAnonymousMissing(error)) {
          includeAnonymous = false;
          continue;
        }
        if (includeVotes && isCivSnapVotesRelationshipMissing(error)) {
          includeVotes = false;
          continue;
        }
        rethrow;
      }
    }

    if (response is! List) {
      return null;
    }

    CivSnapReport? closest;
    double? minDistance;
    for (final row in response) {
      if (row is! Map<String, dynamic>) {
        continue;
      }
      final report = CivSnapReport.fromJson(row);
      final distance = _distanceMeters(
        latitude,
        longitude,
        report.latitude,
        report.longitude,
      );
      if (distance <= radiusMeters && (minDistance == null || distance < minDistance)) {
        closest = report;
        minDistance = distance;
      }
    }
    return closest;
  }

  Future<CivSnapReport> submitReport({
    required String title,
    String? description,
    String? locationLabel,
    required double latitude,
    required double longitude,
    double? accuracyMeters,
    XFile? photo,
    String? userIdOverride,
    bool isAnonymous = false,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    String? photoUrl;
    if (photo != null) {
      photoUrl = await _uploadPhoto(photo, userId);
    }

    final municipality = await _safeFindMunicipality(latitude, longitude);

    final targetUserId = userIdOverride ?? userId;
    var includeStatusComment = true;
    var includeAnonymous = true;
    var includeCorporation = municipality?.corporationId != null;
    CivSnapReport? created;
    String? createdId;
    while (true) {
      final payload = <String, dynamic>{
        'title': title,
        'description': description,
        'photo_url': photoUrl,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy_m': accuracyMeters,
        'location_label': locationLabel,
        'user_id': targetUserId,
        'status': 'pending',
        if (includeAnonymous) 'is_anonymous': isAnonymous,
        if (includeCorporation) 'corporation_id': municipality!.corporationId,
        if (includeCorporation) 'assigned_at': DateTime.now().toIso8601String(),
      }..removeWhere((key, value) => value == null || (value is String && value.isEmpty));
      try {
        final response = await _client
            .from('civsnap_reports')
            .insert(payload)
            .select(
              _reportSelectColumns(
                includeStatusComment: includeStatusComment,
                includeAnonymous: includeAnonymous,
              ),
            )
            .single();
        created = CivSnapReport.fromJson(response);
        createdId = response is Map<String, dynamic> ? response['id'] as String? : null;
        break;
      } on PostgrestException catch (error) {
        if (includeAnonymous && isCivSnapAnonymousMissing(error)) {
          includeAnonymous = false;
          continue;
        }
        if (includeStatusComment && isCivSnapStatusCommentMissing(error)) {
          includeStatusComment = false;
          continue;
        }
        if (includeCorporation && _isCorporationColumnMissing(error)) {
          includeCorporation = false;
          continue;
        }
        rethrow;
      }
    }

    final reportId = createdId ?? created!.id;
    final summaryLabel = municipality != null
        ? 'Assigned to ${municipality.name}'
        : 'No municipality boundary matched';

    AuditLogService.instance.record(
      action: 'civsnap.report.created',
      entityType: 'civsnap_report',
      entityId: reportId,
      summary: '$title · $summaryLabel',
      metadata: {
        'corporation_id': municipality?.corporationId,
        'corporation_name': municipality?.name,
        'is_anonymous': isAnonymous,
        'submitted_by': targetUserId,
      },
    );

    if (municipality?.corporationId != null) {
      NotificationService.instance.notifyCorporation(
        corporationId: municipality!.corporationId!,
        title: 'New CivSnap report: $title',
        body: locationLabel ?? municipality.name,
        category: 'civsnap',
        entityType: 'civsnap_report',
        entityId: reportId,
        metadata: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );
    }
    return created!;
  }

  Future<MunicipalityMatch?> _safeFindMunicipality(double lat, double lng) async {
    try {
      return await BoundaryService.instance.findMunicipality(
        latitude: lat,
        longitude: lng,
      );
    } catch (_) {
      return null;
    }
  }

  bool _isCorporationColumnMissing(PostgrestException error) {
    final msg = error.message.toLowerCase();
    return (msg.contains('corporation_id') || msg.contains('assigned_at')) && msg.contains('column');
  }

  Future<List<CivSnapReport>> fetchReports({
    String? status,
    int limit = 50,
  }) async {
    final readClient = _readClient();
    List<dynamic> response;
    var includeVotes = true;
    var includeStatusComment = true;
    var includeAnonymous = true;
    while (true) {
      try {
        final query = readClient.from('civsnap_reports').select(
              _reportSelect(
                includeVotes: includeVotes,
                includeStatusComment: includeStatusComment,
                includeAnonymous: includeAnonymous,
              ),
            );
        if (status != null) {
          query.eq('status', status);
        }
        response = await query.order('created_at', ascending: false).limit(limit);
        break;
      } on PostgrestException catch (error) {
        if (includeStatusComment && isCivSnapStatusCommentMissing(error)) {
          includeStatusComment = false;
          continue;
        }
        if (includeAnonymous && isCivSnapAnonymousMissing(error)) {
          includeAnonymous = false;
          continue;
        }
        if (includeVotes && isCivSnapVotesRelationshipMissing(error)) {
          includeVotes = false;
          continue;
        }
        rethrow;
      }
    }
    if (response is! List) {
      return [];
    }
    return response
        .whereType<Map<String, dynamic>>()
        .map(CivSnapReport.fromJson)
        .toList();
  }

  Future<List<CivSnapReport>> fetchAllReports({
    String? status,
    int pageSize = 200,
  }) async {
    final reports = <CivSnapReport>[];
    var offset = 0;
    final readClient = _readClient();
    var includeVotes = true;
    var includeStatusComment = true;
    var includeAnonymous = true;
    while (true) {
      List<dynamic> response;
      try {
        final query = readClient.from('civsnap_reports').select(
              _reportSelect(
                includeVotes: includeVotes,
                includeStatusComment: includeStatusComment,
                includeAnonymous: includeAnonymous,
              ),
            );
        if (status != null) {
          query.eq('status', status);
        }
        response =
            await query.order('created_at', ascending: false).range(offset, offset + pageSize - 1);
      } on PostgrestException catch (error) {
        if (includeStatusComment && isCivSnapStatusCommentMissing(error)) {
          includeStatusComment = false;
          continue;
        }
        if (includeAnonymous && isCivSnapAnonymousMissing(error)) {
          includeAnonymous = false;
          continue;
        }
        if (includeVotes && isCivSnapVotesRelationshipMissing(error)) {
          includeVotes = false;
          continue;
        }
        rethrow;
      }
      if (response is! List) {
        break;
      }
      final batch = response.whereType<Map<String, dynamic>>().map(CivSnapReport.fromJson).toList();
      reports.addAll(batch);
      if (batch.length < pageSize) {
        break;
      }
      offset += pageSize;
    }
    return reports;
  }

  Future<Map<String, int>> fetchStatusCounts() async {
    final response = await _readClient().from('civsnap_reports').select('status');
    if (response is! List) {
      return {};
    }
    final counts = <String, int>{};
    for (final row in response) {
      if (row is! Map<String, dynamic>) {
        continue;
      }
      final status = (row['status'] ?? 'open').toString();
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    String? statusComment,
  }) async {
    String? previousStatus;
    String? reporterId;
    String? title;
    try {
      final existing = await _client
          .from('civsnap_reports')
          .select('status,user_id,title')
          .eq('id', reportId)
          .maybeSingle();
      if (existing is Map<String, dynamic>) {
        previousStatus = existing['status'] as String?;
        reporterId = existing['user_id'] as String?;
        title = existing['title'] as String?;
      }
    } catch (_) {}

    final payload = <String, dynamic>{'status': status};
    if (statusComment != null) {
      final trimmed = statusComment.trim();
      payload['status_comment'] = trimmed.isEmpty ? null : trimmed;
    }
    await _client.from('civsnap_reports').update(payload).eq('id', reportId);

    AuditLogService.instance.record(
      action: 'civsnap.report.status_updated',
      entityType: 'civsnap_report',
      entityId: reportId,
      summary: 'Status: ${previousStatus ?? 'unknown'} → $status',
      beforeData: {'status': previousStatus},
      afterData: {'status': status, 'status_comment': statusComment},
    );

    if (reporterId != null) {
      NotificationService.instance.notifyUser(
        userId: reporterId,
        title: 'Update on your report${title != null ? ': $title' : ''}',
        body: 'New status: $status${statusComment != null && statusComment.trim().isNotEmpty ? ' · $statusComment' : ''}',
        category: 'civsnap',
        entityType: 'civsnap_report',
        entityId: reportId,
      );
    }
  }

  Future<void> voteForReport(String reportId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _client.from('civsnap_votes').upsert(
      {
        'report_id': reportId,
        'user_id': userId,
      },
      onConflict: 'report_id,user_id',
    );
  }

  Future<String> _uploadPhoto(XFile photo, String userId) async {
    final storage = _client.storage.from('civsnap');
    final bytes = await photo.readAsBytes();
    final extension = _extensionFor(photo);
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}$extension';
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: _contentTypeFor(extension), upsert: true),
    );
    return path;
  }

  static double _distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const radius = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c;
  }

  static double _toRadians(double degrees) => degrees * (pi / 180);

  static String _extensionFor(XFile file) {
    final name = file.name;
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1) {
      return '.jpg';
    }
    return name.substring(dotIndex);
  }

  static String _contentTypeFor(String extension) {
    switch (extension.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }
}
