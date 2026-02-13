/// Optional metadata attached to API responses.
class ResponseMeta {
  final DateTime? serverTime;
  final String? requestId;

  const ResponseMeta({
    this.serverTime,
    this.requestId,
  });

  factory ResponseMeta.fromJson(Map<String, dynamic> json) {
    return ResponseMeta(
      serverTime: json['server_time'] != null
          ? DateTime.tryParse(json['server_time'].toString())
          : null,
      requestId: json['request_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (serverTime != null) 'server_time': serverTime!.toIso8601String(),
      if (requestId != null) 'request_id': requestId,
    };
  }
}
