import 'dart:collection';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Deterministic short hash from a map payload (sorted keys + sha256 prefix).
/// Used to derive idempotency keys that are stable across retries of the
/// same logical action, even if the UUID would differ.
String stablePayloadHash(Map<String, dynamic> payload) {
  final sorted = SplayTreeMap<String, dynamic>.from(payload);
  final json = jsonEncode(sorted);
  return sha256.convert(utf8.encode(json)).toString().substring(0, 12);
}
