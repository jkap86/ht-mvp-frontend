import 'draft_dtos.dart';

class GetDraftResponse {
  final DraftDto draft;
  final List<DraftOrderEntryDto> order;
  final List<DraftPickDto> picks;

  const GetDraftResponse({
    required this.draft,
    this.order = const [],
    this.picks = const [],
  });

  factory GetDraftResponse.fromJson(Map<String, dynamic> json) {
    return GetDraftResponse(
      draft: DraftDto.fromJson(json['draft'] as Map<String, dynamic>? ?? json),
      order: (json['order'] as List<dynamic>?)
              ?.map((o) => DraftOrderEntryDto.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
      picks: (json['picks'] as List<dynamic>?)
              ?.map((p) => DraftPickDto.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ListDraftsResponse {
  final List<DraftDto> drafts;

  const ListDraftsResponse({required this.drafts});

  factory ListDraftsResponse.fromJson(List<dynamic> json) {
    return ListDraftsResponse(
      drafts: json.map((d) => DraftDto.fromJson(d as Map<String, dynamic>)).toList(),
    );
  }
}

class DraftPicksResponse {
  final List<DraftPickDto> picks;

  const DraftPicksResponse({required this.picks});

  factory DraftPicksResponse.fromJson(List<dynamic> json) {
    return DraftPicksResponse(
      picks: json.map((p) => DraftPickDto.fromJson(p as Map<String, dynamic>)).toList(),
    );
  }
}

class DraftConfigResponse {
  final Map<String, dynamic> config;

  const DraftConfigResponse({required this.config});

  factory DraftConfigResponse.fromJson(Map<String, dynamic> json) {
    return DraftConfigResponse(config: json);
  }
}

class AvailablePickAssetsResponse {
  final List<DraftPickAssetDto> pickAssets;

  const AvailablePickAssetsResponse({required this.pickAssets});

  factory AvailablePickAssetsResponse.fromJson(List<dynamic> json) {
    return AvailablePickAssetsResponse(
      pickAssets: json.map((p) => DraftPickAssetDto.fromJson(p as Map<String, dynamic>)).toList(),
    );
  }
}
