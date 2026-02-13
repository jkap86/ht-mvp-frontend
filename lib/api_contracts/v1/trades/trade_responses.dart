import 'trade_dtos.dart';

class GetTradeResponse {
  final TradeDto trade;

  const GetTradeResponse({required this.trade});

  factory GetTradeResponse.fromJson(Map<String, dynamic> json) {
    return GetTradeResponse(trade: TradeDto.fromJson(json));
  }
}

class ListTradesResponse {
  final List<TradeDto> trades;

  const ListTradesResponse({required this.trades});

  factory ListTradesResponse.fromJson(List<dynamic> json) {
    return ListTradesResponse(
      trades: json.map((t) => TradeDto.fromJson(t as Map<String, dynamic>)).toList(),
    );
  }
}
