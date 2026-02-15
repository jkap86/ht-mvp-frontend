import '../common/enums.dart';
import '../../../core/utils/date_sentinel.dart';

class NotificationDto {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final int? leagueId;
  final String? leagueName;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final bool isRead;

  const NotificationDto({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.leagueId,
    this.leagueName,
    this.data,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      id: json['id']?.toString() ?? '',
      type: NotificationType.fromString(json['type'] as String? ?? 'message_received'),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      leagueId: json['league_id'] as int?,
      leagueName: json['league_name'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? epochUtc(),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'title': title,
      'body': body,
      'league_id': leagueId,
      'league_name': leagueName,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }
}

class NotificationPreferencesDto {
  final Map<String, bool> preferences;

  const NotificationPreferencesDto({required this.preferences});

  factory NotificationPreferencesDto.fromJson(Map<String, dynamic> json) {
    final prefs = <String, bool>{};
    json.forEach((key, value) {
      if (value is bool) prefs[key] = value;
    });
    return NotificationPreferencesDto(preferences: prefs);
  }

  Map<String, dynamic> toJson() => preferences;
}
