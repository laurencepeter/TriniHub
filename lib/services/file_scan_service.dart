import 'package:supabase_flutter/supabase_flutter.dart';

class FileScanService {
  FileScanService._();
  static final FileScanService instance = FileScanService._();

  final SupabaseClient _client = Supabase.instance.client;

  Future<void> recordScan({
    required String fileId,
    required String departmentId,
    required String eventType,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    await _client.from('file_scans').insert({
      'file_id': fileId,
      'department_id': departmentId,
      'user_id': userId,
      'event_type': eventType,
    });
  }
}
