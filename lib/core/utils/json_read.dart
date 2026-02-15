// Helpers for reading socket JSON payloads that may arrive in either
// snake_case or camelCase depending on the backend serializer path.
//
// Each function checks camelCase first (common path) then falls back
// to snake_case.

int? readIntEither(Map<String, dynamic> j, String snake, String camel) {
  final v = j.containsKey(camel) ? j[camel] : j[snake];
  if (v is int) return v;
  if (v is num) return v.toInt();
  return null;
}

String? readStringEither(Map<String, dynamic> j, String snake, String camel) {
  final v = j.containsKey(camel) ? j[camel] : j[snake];
  return v is String ? v : v?.toString();
}

bool? readBoolEither(Map<String, dynamic> j, String snake, String camel) {
  final v = j.containsKey(camel) ? j[camel] : j[snake];
  if (v is bool) return v;
  return null;
}
