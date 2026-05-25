import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';

class MunicipalityMatch {
  final String? corporationId;
  final String name;

  const MunicipalityMatch({required this.corporationId, required this.name});
}

class _Boundary {
  final String name;
  final String? corporationId;
  final List<List<List<double>>> rings;

  const _Boundary({
    required this.name,
    required this.corporationId,
    required this.rings,
  });
}

class BoundaryService {
  BoundaryService._();
  static final BoundaryService instance = BoundaryService._();

  static const String _assetPath = 'lib/assets/data/tt_municipalities.geojson';

  List<_Boundary>? _cache;
  Map<String, String>? _nameToId;

  Future<List<_Boundary>> _loadBoundaries() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final features = decoded['features'] as List? ?? const [];
    final boundaries = <_Boundary>[];
    for (final feature in features) {
      if (feature is! Map<String, dynamic>) continue;
      final props = feature['properties'] as Map<String, dynamic>? ?? const {};
      final geometry = feature['geometry'] as Map<String, dynamic>?;
      if (geometry == null) continue;
      final name = (props['name'] ?? '').toString();
      final corpId = props['corporation_id']?.toString();
      final rings = _extractRings(geometry);
      if (name.isEmpty || rings.isEmpty) continue;
      boundaries.add(_Boundary(
        name: name,
        corporationId: corpId == null || corpId.isEmpty ? null : corpId,
        rings: rings,
      ));
    }
    _cache = boundaries;
    return boundaries;
  }

  Future<Map<String, String>> _loadNameToCorporationId() async {
    if (_nameToId != null) return _nameToId!;
    final client = Supabase.instance.client;
    try {
      final response = await client.from('corporations').select('id,name');
      final map = <String, String>{};
      if (response is List) {
        for (final row in response.whereType<Map<String, dynamic>>()) {
          final name = (row['name'] ?? '').toString().trim().toLowerCase();
          final id = (row['id'] ?? '').toString();
          if (name.isNotEmpty && id.isNotEmpty) {
            map[name] = id;
          }
        }
      }
      _nameToId = map;
      return map;
    } catch (_) {
      _nameToId = {};
      return _nameToId!;
    }
  }

  Future<MunicipalityMatch?> findMunicipality({
    required double latitude,
    required double longitude,
  }) async {
    final boundaries = await _loadBoundaries();
    _Boundary? match;
    for (final boundary in boundaries) {
      if (_pointInRings(longitude, latitude, boundary.rings)) {
        match = boundary;
        break;
      }
    }
    if (match == null) return null;

    var corporationId = match.corporationId;
    if (corporationId == null) {
      final lookup = await _loadNameToCorporationId();
      corporationId = lookup[match.name.trim().toLowerCase()];
    }
    return MunicipalityMatch(
      corporationId: corporationId,
      name: match.name,
    );
  }

  static List<List<List<double>>> _extractRings(Map<String, dynamic> geometry) {
    final type = (geometry['type'] ?? '').toString();
    final coordinates = geometry['coordinates'];
    if (type == 'Polygon' && coordinates is List) {
      return _ringsFromPolygon(coordinates);
    }
    if (type == 'MultiPolygon' && coordinates is List) {
      final all = <List<List<double>>>[];
      for (final polygon in coordinates) {
        if (polygon is List) {
          all.addAll(_ringsFromPolygon(polygon));
        }
      }
      return all;
    }
    return const [];
  }

  static List<List<List<double>>> _ringsFromPolygon(List polygon) {
    final rings = <List<List<double>>>[];
    for (final ring in polygon) {
      if (ring is! List) continue;
      final coords = <List<double>>[];
      for (final point in ring) {
        if (point is! List || point.length < 2) continue;
        final lng = (point[0] as num).toDouble();
        final lat = (point[1] as num).toDouble();
        coords.add([lng, lat]);
      }
      if (coords.length >= 3) rings.add(coords);
    }
    return rings;
  }

  static bool _pointInRings(double x, double y, List<List<List<double>>> rings) {
    if (rings.isEmpty) return false;
    if (!_pointInPolygon(x, y, rings.first)) return false;
    for (var i = 1; i < rings.length; i++) {
      if (_pointInPolygon(x, y, rings[i])) return false;
    }
    return true;
  }

  static bool _pointInPolygon(double x, double y, List<List<double>> ring) {
    var inside = false;
    final n = ring.length;
    for (var i = 0, j = n - 1; i < n; j = i++) {
      final xi = ring[i][0];
      final yi = ring[i][1];
      final xj = ring[j][0];
      final yj = ring[j][1];
      final intersects = ((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / ((yj - yi) == 0 ? 1e-12 : (yj - yi)) + xi);
      if (intersects) inside = !inside;
    }
    return inside;
  }
}
