import 'package:supabase_flutter/supabase_flutter.dart';

/// Custody event kinds recorded against a file.
class FileEventType {
  static const String received = 'received';
  static const String checkedOut = 'checked_out';
  static const String transferred = 'transferred';

  static String label(String type) {
    switch (type) {
      case received:
        return 'Received';
      case checkedOut:
        return 'Checked out';
      case transferred:
        return 'Transferred';
      case 'in':
        return 'Received';
      case 'out':
        return 'Checked out';
      default:
        return type;
    }
  }
}

class Department {
  final String id;
  final String name;

  const Department({required this.id, required this.name});

  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(
      id: map['id'].toString(),
      name: (map['name'] as String?)?.trim().isNotEmpty == true
          ? map['name'] as String
          : 'Unnamed department',
    );
  }
}

class FileScanEvent {
  final String id;
  final String fileId;
  final String eventType;
  final String? departmentId;
  final String? actorLabel;
  final String? custodianLabel;
  final String? note;
  final DateTime scanTime;

  const FileScanEvent({
    required this.id,
    required this.fileId,
    required this.eventType,
    required this.scanTime,
    this.departmentId,
    this.actorLabel,
    this.custodianLabel,
    this.note,
  });

  factory FileScanEvent.fromMap(Map<String, dynamic> map) {
    return FileScanEvent(
      id: map['id'].toString(),
      fileId: map['file_id'].toString(),
      eventType: (map['event_type'] as String?) ?? 'received',
      departmentId: map['department_id']?.toString(),
      actorLabel: map['actor_label'] as String?,
      custodianLabel: map['custodian_label'] as String?,
      note: map['note'] as String?,
      scanTime: DateTime.tryParse(map['scan_time']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}

class FileScanService {
  FileScanService._();
  static final FileScanService instance = FileScanService._();

  final SupabaseClient _client = Supabase.instance.client;

  String _currentUserLabel() {
    final user = _client.auth.currentUser;
    final metadata = user?.userMetadata;
    final raw = metadata?['full_name'] ??
        metadata?['name'] ??
        metadata?['display_name'] ??
        user?.email;
    final label = raw?.toString().trim();
    return (label == null || label.isEmpty) ? 'Staff member' : label;
  }

  Future<List<Department>> fetchDepartments() async {
    final rows = await _client.from('departments').select().order('name');
    return (rows as List)
        .map((row) => Department.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Make sure a scanned file exists so the custody insert's FK is satisfied.
  Future<void> ensureFile(String fileId, {String? description}) async {
    await _client.from('files').upsert(
      {
        'id': fileId,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      },
      onConflict: 'id',
    );
  }

  /// Record a custody event. [actorId] is always the signed-in scanner; the
  /// custodian is who now holds the file — the scanned colleague on a hand-off,
  /// or the scanner themselves on a receipt.
  Future<void> recordCustodyEvent({
    required String fileId,
    required String eventType,
    String? departmentId,
    String? custodianId,
    String? custodianLabel,
    String? note,
  }) async {
    final actorId = _client.auth.currentUser?.id;
    if (actorId == null) {
      throw Exception('User not authenticated');
    }
    final actorLabel = _currentUserLabel();
    await ensureFile(fileId);
    await _client.from('file_scans').insert({
      'file_id': fileId,
      'department_id': departmentId,
      'user_id': actorId,
      'actor_id': actorId,
      'actor_label': actorLabel,
      'custodian_id': custodianId ?? actorId,
      'custodian_label': custodianLabel ?? actorLabel,
      'event_type': eventType,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
  }

  Future<List<FileScanEvent>> fetchFileHistory(String fileId) async {
    final rows = await _client
        .from('file_scans')
        .select()
        .eq('file_id', fileId)
        .order('scan_time', ascending: false);
    return (rows as List)
        .map((row) => FileScanEvent.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Legacy helper kept for the original in/out scanner path.
  Future<void> recordScan({
    required String fileId,
    required String departmentId,
    required String eventType,
  }) async {
    await recordCustodyEvent(
      fileId: fileId,
      departmentId: departmentId,
      eventType: eventType,
    );
  }
}
