import 'waiver_dtos.dart';

class ListClaimsResponse {
  final List<WaiverClaimDto> claims;

  const ListClaimsResponse({required this.claims});

  factory ListClaimsResponse.fromJson(List<dynamic> json) {
    return ListClaimsResponse(
      claims: json.map((c) => WaiverClaimDto.fromJson(c as Map<String, dynamic>)).toList(),
    );
  }
}

class WaiverPriorityResponse {
  final List<WaiverPriorityDto> priorities;

  const WaiverPriorityResponse({required this.priorities});

  factory WaiverPriorityResponse.fromJson(List<dynamic> json) {
    return WaiverPriorityResponse(
      priorities: json.map((p) => WaiverPriorityDto.fromJson(p as Map<String, dynamic>)).toList(),
    );
  }
}

class FaabBudgetResponse {
  final List<FaabBudgetDto> budgets;

  const FaabBudgetResponse({required this.budgets});

  factory FaabBudgetResponse.fromJson(List<dynamic> json) {
    return FaabBudgetResponse(
      budgets: json.map((b) => FaabBudgetDto.fromJson(b as Map<String, dynamic>)).toList(),
    );
  }
}

class WaiverWireResponse {
  final List<WaiverClaimDto> claims;
  final List<WaiverPriorityDto> priorities;

  const WaiverWireResponse({required this.claims, required this.priorities});

  factory WaiverWireResponse.fromJson(Map<String, dynamic> json) {
    return WaiverWireResponse(
      claims: (json['claims'] as List<dynamic>?)
              ?.map((c) => WaiverClaimDto.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      priorities: (json['priorities'] as List<dynamic>?)
              ?.map((p) => WaiverPriorityDto.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
