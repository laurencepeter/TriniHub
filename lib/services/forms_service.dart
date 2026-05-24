import 'dart:math';
import 'dart:typed_data';

import 'package:local_app_tt/services/audit_log_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegionOption {
  final String id;
  final String name;

  const RegionOption({required this.id, required this.name});
}

class FormTemplate {
  final String id;
  final String title;
  final String description;
  final String scope;
  final String status;
  final String? pdfBucket;
  final String? regionId;
  final String? regionName;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FormTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.scope,
    required this.status,
    required this.pdfBucket,
    required this.regionId,
    required this.regionName,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FormTemplate.fromJson(Map<String, dynamic> json) {
    final region = json['region'] as Map<String, dynamic>?;
    return FormTemplate(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      scope: json['scope'] as String? ?? 'public',
      status: json['status'] as String? ?? 'draft',
      pdfBucket: json['pdf_output_bucket'] as String?,
      regionId: json['region_id'] as String?,
      regionName: region?['name'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class FormFieldTemplate {
  final String id;
  final String formId;
  final String label;
  final String fieldType;
  final bool isRequired;
  final List<String> options;
  final int position;

  const FormFieldTemplate({
    required this.id,
    required this.formId,
    required this.label,
    required this.fieldType,
    required this.isRequired,
    required this.options,
    required this.position,
  });

  factory FormFieldTemplate.fromJson(Map<String, dynamic> json) {
    return FormFieldTemplate(
      id: json['id'] as String,
      formId: json['form_id'] as String,
      label: json['label'] as String? ?? '',
      fieldType: json['field_type'] as String? ?? 'short_text',
      isRequired: json['is_required'] as bool? ?? false,
      options: _stringList(json['options']),
      position: json['position'] as int? ?? 0,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((entry) => entry.toString()).toList();
    }
    return [];
  }
}

class FormFieldDraft {
  final String label;
  final String fieldType;
  final bool isRequired;
  final List<String> options;
  final int position;

  const FormFieldDraft({
    required this.label,
    required this.fieldType,
    required this.isRequired,
    required this.options,
    required this.position,
  });
}

class FormSubmissionSummary {
  final String id;
  final String formId;
  final String formTitle;
  final String status;
  final String? summary;
  final String? locationLabel;
  final String? regionName;
  final DateTime createdAt;

  const FormSubmissionSummary({
    required this.id,
    required this.formId,
    required this.formTitle,
    required this.status,
    required this.summary,
    required this.locationLabel,
    required this.regionName,
    required this.createdAt,
  });

  factory FormSubmissionSummary.fromJson(Map<String, dynamic> json) {
    final form = json['form'] as Map<String, dynamic>?;
    final region = json['region'] as Map<String, dynamic>?;
    return FormSubmissionSummary(
      id: json['id'] as String,
      formId: json['form_id'] as String,
      formTitle: form?['title'] as String? ?? 'Form',
      status: json['status'] as String? ?? 'submitted',
      summary: json['summary'] as String?,
      locationLabel: json['location_label'] as String?,
      regionName: region?['name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class FormSubmissionDetail {
  final String id;
  final String formId;
  final String formTitle;
  final String status;
  final Map<String, dynamic> responses;
  final String? locationLabel;
  final double? latitude;
  final double? longitude;
  final String? summary;
  final DateTime createdAt;
  final String? submitterId;

  const FormSubmissionDetail({
    required this.id,
    required this.formId,
    required this.formTitle,
    required this.status,
    required this.responses,
    required this.locationLabel,
    required this.latitude,
    required this.longitude,
    required this.summary,
    required this.createdAt,
    required this.submitterId,
  });

  factory FormSubmissionDetail.fromJson(Map<String, dynamic> json) {
    final form = json['form'] as Map<String, dynamic>?;
    return FormSubmissionDetail(
      id: json['id'] as String,
      formId: json['form_id'] as String,
      formTitle: form?['title'] as String? ?? 'Form',
      status: json['status'] as String? ?? 'submitted',
      responses: (json['responses'] as Map<String, dynamic>? ?? {}),
      locationLabel: json['location_label'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      summary: json['summary'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      submitterId: json['submitter_id'] as String?,
    );
  }
}

class NearbySubmission {
  final String id;
  final String? summary;
  final String status;
  final double distanceKm;
  final DateTime createdAt;

  const NearbySubmission({
    required this.id,
    required this.summary,
    required this.status,
    required this.distanceKm,
    required this.createdAt,
  });
}

class FormsService {
  FormsService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<RegionOption>> fetchRegions() async {
    final response = await _client.from('corporations').select('id,name').order('name');
    if (response is! List) {
      return [];
    }
    return response
        .whereType<Map<String, dynamic>>()
        .map((row) => RegionOption(id: row['id'] as String, name: row['name'] as String))
        .toList();
  }

  Future<List<FormTemplate>> fetchForms({String? scope, bool includeDrafts = false}) async {
    var query = _client
        .from('form_templates')
        .select(
          'id,title,description,scope,status,pdf_output_bucket,region_id,created_at,updated_at,created_by,region:corporations(name)',
        );
    if (scope != null) {
      query = query.eq('scope', scope);
    }
    if (!includeDrafts) {
      query = query.eq('status', 'published');
    }
    final response = await query.order('created_at', ascending: false);
    if (response is! List) {
      return [];
    }
    return response
        .whereType<Map<String, dynamic>>()
        .map(FormTemplate.fromJson)
        .toList();
  }

  Future<List<FormFieldTemplate>> fetchFields(String formId) async {
    final response = await _client
        .from('form_fields')
        .select('id,form_id,label,field_type,is_required,options,position')
        .eq('form_id', formId)
        .order('position', ascending: true);
    if (response is! List) {
      return [];
    }
    return response
        .whereType<Map<String, dynamic>>()
        .map(FormFieldTemplate.fromJson)
        .toList();
  }

  Future<String?> _fetchCurrentCorporationId() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }
    final response = await _client
        .from('user_profiles')
        .select('corporation_id')
        .eq('user_id', userId)
        .maybeSingle();
    if (response == null || response is! Map<String, dynamic>) {
      return null;
    }
    return response['corporation_id'] as String?;
  }

  Future<FormTemplate> createForm({
    required String title,
    required String description,
    required String scope,
    required String status,
    String? regionId,
    String? pdfBucket,
    required List<FormFieldDraft> fields,
  }) async {
    final formPayload = <String, dynamic>{
      'title': title,
      'description': description,
      'scope': scope,
      'status': status,
      'pdf_output_bucket': pdfBucket,
      'region_id': regionId,
      'created_by': _client.auth.currentUser?.id,
    }..removeWhere((key, value) => value == null);

    final inserted = await _client
        .from('form_templates')
        .insert(formPayload)
        .select(
          'id,title,description,scope,status,pdf_output_bucket,region_id,created_at,updated_at,created_by,region:corporations(name)',
        )
        .single();
    if (inserted is! Map<String, dynamic>) {
      throw const PostgrestException(message: 'Unable to create form.');
    }

    final form = FormTemplate.fromJson(inserted);
    if (fields.isNotEmpty) {
      final fieldPayloads = fields
          .map((field) => {
                'form_id': form.id,
                'label': field.label,
                'field_type': field.fieldType,
                'is_required': field.isRequired,
                'options': field.options,
                'position': field.position,
              })
          .toList();
      await _client.from('form_fields').insert(fieldPayloads);
    }
    AuditLogService.instance.record(
      action: 'form.created',
      entityType: 'form_template',
      entityId: form.id,
      summary: '${form.title} (${form.scope}/${form.status})',
      metadata: {'field_count': fields.length},
    );
    return form;
  }

  Future<FormTemplate?> fetchFormById(String formId) async {
    final response = await _client
        .from('form_templates')
        .select(
          'id,title,description,scope,status,pdf_output_bucket,region_id,created_at,updated_at,created_by,region:corporations(name)',
        )
        .eq('id', formId)
        .maybeSingle();
    if (response is! Map<String, dynamic>) return null;
    return FormTemplate.fromJson(response);
  }

  Future<FormTemplate> updateForm({
    required String formId,
    required String title,
    required String description,
    required String scope,
    required String status,
    String? regionId,
    String? pdfBucket,
    required List<FormFieldDraft> fields,
  }) async {
    final before = await fetchFormById(formId);
    final payload = <String, dynamic>{
      'title': title,
      'description': description,
      'scope': scope,
      'status': status,
      'pdf_output_bucket': pdfBucket,
      'region_id': regionId,
    };
    final updated = await _client
        .from('form_templates')
        .update(payload)
        .eq('id', formId)
        .select(
          'id,title,description,scope,status,pdf_output_bucket,region_id,created_at,updated_at,created_by,region:corporations(name)',
        )
        .single();
    if (updated is! Map<String, dynamic>) {
      throw const PostgrestException(message: 'Unable to update form.');
    }

    await _client.from('form_fields').delete().eq('form_id', formId);
    if (fields.isNotEmpty) {
      final fieldPayloads = fields
          .map((field) => {
                'form_id': formId,
                'label': field.label,
                'field_type': field.fieldType,
                'is_required': field.isRequired,
                'options': field.options,
                'position': field.position,
              })
          .toList();
      await _client.from('form_fields').insert(fieldPayloads);
    }

    final form = FormTemplate.fromJson(updated);
    AuditLogService.instance.record(
      action: 'form.updated',
      entityType: 'form_template',
      entityId: formId,
      summary: '${form.title} (${form.scope}/${form.status})',
      beforeData: before == null
          ? null
          : {
              'title': before.title,
              'description': before.description,
              'scope': before.scope,
              'status': before.status,
            },
      afterData: {
        'title': title,
        'description': description,
        'scope': scope,
        'status': status,
        'field_count': fields.length,
      },
    );
    return form;
  }

  Future<void> updateFormStatus({required String formId, required String status}) async {
    String? previousStatus;
    String? title;
    try {
      final existing = await _client
          .from('form_templates')
          .select('status,title')
          .eq('id', formId)
          .maybeSingle();
      if (existing is Map<String, dynamic>) {
        previousStatus = existing['status'] as String?;
        title = existing['title'] as String?;
      }
    } catch (_) {}
    await _client.from('form_templates').update({'status': status}).eq('id', formId);

    final action = status == 'published'
        ? 'form.published'
        : status == 'archived'
            ? 'form.archived'
            : 'form.unpublished';
    AuditLogService.instance.record(
      action: action,
      entityType: 'form_template',
      entityId: formId,
      summary: title ?? formId,
      beforeData: {'status': previousStatus},
      afterData: {'status': status},
    );
  }

  Future<List<FormSubmissionSummary>> fetchSubmissions({String? scope}) async {
    var query = _client
        .from('form_submissions')
        .select('id,form_id,status,summary,location_label,created_at,form:form_templates(title,scope),region:corporations(name)');
    if (scope != null) {
      query = query.eq('form.scope', scope);
    }
    final response = await query.order('created_at', ascending: false);
    if (response is! List) {
      return [];
    }
    return response
        .whereType<Map<String, dynamic>>()
        .map(FormSubmissionSummary.fromJson)
        .toList();
  }

  Future<FormSubmissionDetail?> fetchSubmissionDetail(String submissionId) async {
    final response = await _client
        .from('form_submissions')
        .select('id,form_id,submitter_id,status,summary,responses,location_label,latitude,longitude,created_at,form:form_templates(title)')
        .eq('id', submissionId)
        .maybeSingle();
    if (response == null || response is! Map<String, dynamic>) {
      return null;
    }
    return FormSubmissionDetail.fromJson(response);
  }

  Future<void> updateSubmissionStatus({required String submissionId, required String status}) async {
    await _client.from('form_submissions').update({'status': status}).eq('id', submissionId);
  }

  Future<List<NearbySubmission>> fetchNearbySubmissions({
    required String formId,
    required double latitude,
    required double longitude,
    double radiusKm = 0.75,
  }) async {
    final latDelta = radiusKm / 110.574;
    final lonDelta = radiusKm / (111.320 * cos(latitude * pi / 180));
    final response = await _client
        .from('form_submissions')
        .select('id,summary,status,latitude,longitude,created_at')
        .eq('form_id', formId)
        .gte('latitude', latitude - latDelta)
        .lte('latitude', latitude + latDelta)
        .gte('longitude', longitude - lonDelta)
        .lte('longitude', longitude + lonDelta)
        .order('created_at', ascending: false)
        .limit(20);
    if (response is! List) {
      return [];
    }
    final results = <NearbySubmission>[];
    for (final entry in response.whereType<Map<String, dynamic>>()) {
      final lat = (entry['latitude'] as num?)?.toDouble();
      final lon = (entry['longitude'] as num?)?.toDouble();
      if (lat == null || lon == null) {
        continue;
      }
      final distance = _distanceKm(latitude, longitude, lat, lon);
      if (distance <= radiusKm && distance > 0.02) {
        results.add(
          NearbySubmission(
            id: entry['id'] as String,
            summary: entry['summary'] as String?,
            status: entry['status'] as String? ?? 'submitted',
            distanceKm: distance,
            createdAt: DateTime.parse(entry['created_at'] as String),
          ),
        );
      }
    }
    results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return results;
  }

  Future<String> createSubmission({
    required String formId,
    required Map<String, dynamic> responses,
    String? summary,
    double? latitude,
    double? longitude,
    String? locationLabel,
    String? regionId,
  }) async {
    final corporationId = await _fetchCurrentCorporationId();
    final payload = <String, dynamic>{
      'form_id': formId,
      'submitter_id': _client.auth.currentUser?.id,
      'responses': responses,
      'summary': summary,
      'latitude': latitude,
      'longitude': longitude,
      'location_label': locationLabel,
      'region_id': regionId ?? corporationId,
    }..removeWhere((key, value) => value == null);
    final inserted = await _client.from('form_submissions').insert(payload).select('id').single();
    if (inserted is! Map<String, dynamic>) {
      throw const PostgrestException(message: 'Unable to create submission.');
    }
    return inserted['id'] as String;
  }

  Future<String> uploadPhoto({required String folder, required String filename, required List<int> bytes}) async {
    final path = '$folder/$filename';
    final data = Uint8List.fromList(bytes);
    await _client.storage.from('form-uploads').uploadBinary(path, data);
    final url = _client.storage.from('form-uploads').getPublicUrl(path);
    return url;
  }

  Future<void> updateSubmissionResponses({
    required String submissionId,
    required Map<String, dynamic> responses,
  }) async {
    await _client.from('form_submissions').update({'responses': responses}).eq('id', submissionId);
  }

  static double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _deg2rad(double deg) => deg * (pi / 180);
}
