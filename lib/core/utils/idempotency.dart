import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Generates a new idempotency key for mutating operations.
///
/// Call this at the UI action boundary (e.g., button tap) so the same key
/// is reused across retries of the same action.
String newIdempotencyKey() => _uuid.v4();
