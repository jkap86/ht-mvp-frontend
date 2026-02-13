import 'notification_dtos.dart';

class GetPreferencesResponse {
  final NotificationPreferencesDto preferences;

  const GetPreferencesResponse({required this.preferences});

  factory GetPreferencesResponse.fromJson(Map<String, dynamic> json) {
    return GetPreferencesResponse(
      preferences: NotificationPreferencesDto.fromJson(json),
    );
  }
}
