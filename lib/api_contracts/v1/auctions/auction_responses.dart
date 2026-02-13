import 'auction_dtos.dart';

class GetAuctionStateResponse {
  final AuctionStateDto state;

  const GetAuctionStateResponse({required this.state});

  factory GetAuctionStateResponse.fromJson(Map<String, dynamic> json) {
    return GetAuctionStateResponse(state: AuctionStateDto.fromJson(json));
  }
}

class ListLotsResponse {
  final List<AuctionLotDto> lots;

  const ListLotsResponse({required this.lots});

  factory ListLotsResponse.fromJson(List<dynamic> json) {
    return ListLotsResponse(
      lots: json.map((l) => AuctionLotDto.fromJson(l as Map<String, dynamic>)).toList(),
    );
  }
}

class GetBudgetsResponse {
  final List<AuctionBudgetDto> budgets;

  const GetBudgetsResponse({required this.budgets});

  factory GetBudgetsResponse.fromJson(List<dynamic> json) {
    return GetBudgetsResponse(
      budgets: json.map((b) => AuctionBudgetDto.fromJson(b as Map<String, dynamic>)).toList(),
    );
  }
}

class BidHistoryResponse {
  final List<BidHistoryEntryDto> bids;

  const BidHistoryResponse({required this.bids});

  factory BidHistoryResponse.fromJson(List<dynamic> json) {
    return BidHistoryResponse(
      bids: json.map((b) => BidHistoryEntryDto.fromJson(b as Map<String, dynamic>)).toList(),
    );
  }
}
