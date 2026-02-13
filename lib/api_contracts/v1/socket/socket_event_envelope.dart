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
