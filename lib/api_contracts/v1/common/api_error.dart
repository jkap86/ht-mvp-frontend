/// Standard API error response shape.
class ApiErrorDto {
  final String code;
  final String message;
  final Map<String, dynamic>? details;
  final String? requestId;

  const ApiErrorDto({
    required this.code,
    required this.message,
    this.details,
    this.requestId,
  });

  factory ApiErrorDto.fromJson(Map<String, dynamic> json) {
    return ApiErrorDto(
      code: json['code'] as String? ?? 'UNKNOWN',
      message: json['message'] as String? ?? '',
      details: json['details'] as Map<String, dynamic>?,
      requestId: json['request_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      if (details != null) 'details': details,
      if (requestId != null) 'request_id': requestId,
    };
  }
}
