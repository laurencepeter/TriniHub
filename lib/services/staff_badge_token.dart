import 'dart:convert';

/// A short-lived identity token encoded into a staff member's personal QR
/// "badge". A colleague scans it to hand a file to that person, so it must
/// expire quickly (default 60s) to limit reuse.
///
/// Security note: this MVP token is generated and validated on-device and is
/// NOT cryptographically signed — a determined actor could craft one. It is
/// suitable for a pilot/controlled rollout. To harden for production, issue
/// and verify the token through a Supabase Edge Function (HMAC/JWT) so the
/// signing secret never ships in the app; the encode/decode shape here is
/// designed to swap over to that without touching the scan flow.
class StaffBadgeToken {
  final String userId;
  final String label;
  final DateTime expiresAt;

  const StaffBadgeToken({
    required this.userId,
    required this.label,
    required this.expiresAt,
  });

  static const String _type = 'trinihub-badge';
  static const int _version = 1;
  static const String _prefix = 'TBADGE:';

  /// Issue a fresh badge for [userId] that is valid for [ttl].
  factory StaffBadgeToken.issue({
    required String userId,
    required String label,
    Duration ttl = const Duration(seconds: 60),
  }) {
    return StaffBadgeToken(
      userId: userId,
      label: label,
      expiresAt: DateTime.now().add(ttl),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get remaining {
    final left = expiresAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// The string embedded in the QR image.
  String encode() {
    final payload = <String, dynamic>{
      'v': _version,
      't': _type,
      'uid': userId,
      'name': label,
      'exp': expiresAt.millisecondsSinceEpoch,
    };
    return _prefix + base64Url.encode(utf8.encode(json.encode(payload)));
  }

  /// Returns a token if [raw] is a Trini Hub badge QR, otherwise null (so the
  /// scanner can tell a person's badge apart from a file's QR).
  static StaffBadgeToken? tryDecode(String raw) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith(_prefix)) return null;
    try {
      final encoded = trimmed.substring(_prefix.length);
      final decoded =
          json.decode(utf8.decode(base64Url.decode(encoded))) as Map<String, dynamic>;
      if (decoded['t'] != _type) return null;
      final uid = decoded['uid'] as String?;
      final exp = decoded['exp'];
      if (uid == null || uid.isEmpty || exp is! int) return null;
      return StaffBadgeToken(
        userId: uid,
        label: (decoded['name'] as String?)?.trim().isNotEmpty == true
            ? decoded['name'] as String
            : 'Staff member',
        expiresAt: DateTime.fromMillisecondsSinceEpoch(exp),
      );
    } catch (_) {
      return null;
    }
  }
}
