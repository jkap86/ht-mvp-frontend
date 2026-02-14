class SocketEventEnvelope {
  final String eventType;
  final Map<String, dynamic> payload;
  final DateTime? serverTime;
  final int? version;

  const SocketEventEnvelope({
    required this.eventType,
    required this.payload,
    this.serverTime,
    this.version,
  });

  /// Normalize raw socket data into a consistent envelope.
  ///
  /// If the raw JSON contains a `payload` key that is a Map, unwrap it as the
  /// normalized payload. Otherwise, the JSON itself IS the payload.
  ///
  /// Root-level `serverTime` is preserved by merging it into the normalized
  /// payload so downstream event factories that read `json['serverTime']` still
  /// work regardless of whether the backend wrapped the data.
  factory SocketEventEnvelope.fromRaw(String eventType, Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    Map<String, dynamic> normalized;

    if (rawPayload is Map) {
      normalized = rawPayload.cast<String, dynamic>();
      // Merge root-level serverTime into the normalized payload
      if (json.containsKey('serverTime') && !normalized.containsKey('serverTime')) {
        normalized['serverTime'] = json['serverTime'];
      }
    } else {
      normalized = json;
    }

    return SocketEventEnvelope(
      eventType: eventType,
      payload: normalized,
      serverTime: json['serverTime'] != null
          ? DateTime.tryParse(json['serverTime'].toString())
          : null,
      version: json['version'] as int?,
    );
  }

  factory SocketEventEnvelope.fromJson(String eventType, Map<String, dynamic> json) {
    return SocketEventEnvelope(
      eventType: eventType,
      payload: json,
      serverTime: json['serverTime'] != null
          ? DateTime.tryParse(json['serverTime'].toString())
          : null,
      version: json['version'] as int?,
    );
  }
}
