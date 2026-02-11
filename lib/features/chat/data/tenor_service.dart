import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';

/// A single GIF result from the Tenor API.
class TenorGif {
  final String id;
  final String title;
  /// Thumbnail URL (nanogif format ~50KB)
  final String thumbnailUrl;
  /// Full GIF URL (tinygif format ~200KB) — sent in messages
  final String gifUrl;
  final int width;
  final int height;

  const TenorGif({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.gifUrl,
    required this.width,
    required this.height,
  });

  double get aspectRatio => width > 0 ? height / width : 1.0;

  factory TenorGif.fromJson(Map<String, dynamic> json) {
    final mediaFormats = json['media_formats'] as Map<String, dynamic>? ?? {};
    final nanogif = mediaFormats['nanogif'] as Map<String, dynamic>? ?? {};
    final tinygif = mediaFormats['tinygif'] as Map<String, dynamic>? ?? {};
    final nanoDims = (nanogif['dims'] as List?)?.cast<int>() ?? [100, 100];
    return TenorGif(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      thumbnailUrl: nanogif['url'] as String? ?? '',
      gifUrl: tinygif['url'] as String? ?? '',
      width: nanoDims.isNotEmpty ? nanoDims[0] : 100,
      height: nanoDims.length > 1 ? nanoDims[1] : 100,
    );
  }
}

/// GIF search categories for quick access.
enum GifCategory {
  trending('Trending', ''),
  reactions('Reactions', 'reaction'),
  sports('Sports', 'sports'),
  nfl('NFL', 'nfl football'),
  celebration('Celebrate', 'celebration'),
  fail('Fail', 'fail');

  final String label;
  final String query;
  const GifCategory(this.label, this.query);
}

/// Service for searching GIFs via the Tenor API v2.
class TenorService {
  static const _baseUrl = 'https://tenor.googleapis.com/v2';
  static const _clientKey = 'hypetrain_ff';
  static const _limit = 30;

  final String _apiKey;
  Timer? _debounceTimer;
  String? _lastSearchNext;

  TenorService(this._apiKey);

  bool get isAvailable => _apiKey.isNotEmpty;

  /// Search for GIFs with a query string.
  Future<List<TenorGif>> search(String query, {String? pos}) async {
    if (!isAvailable || query.isEmpty) return [];

    final params = {
      'q': query,
      'key': _apiKey,
      'client_key': _clientKey,
      'limit': '$_limit',
      'media_filter': 'nanogif,tinygif',
      if (pos != null) 'pos': pos,
    };

    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: params);
    final response = await http.get(uri);
    if (response.statusCode != 200) return [];

    final data = json.decode(response.body) as Map<String, dynamic>;
    _lastSearchNext = data['next'] as String?;
    return _parseResults(data);
  }

  /// Get trending GIFs.
  Future<List<TenorGif>> trending({String? pos}) async {
    if (!isAvailable) return [];

    final params = {
      'key': _apiKey,
      'client_key': _clientKey,
      'limit': '$_limit',
      'media_filter': 'nanogif,tinygif',
      if (pos != null) 'pos': pos,
    };

    final uri = Uri.parse('$_baseUrl/featured').replace(queryParameters: params);
    final response = await http.get(uri);
    if (response.statusCode != 200) return [];

    final data = json.decode(response.body) as Map<String, dynamic>;
    _lastSearchNext = data['next'] as String?;
    return _parseResults(data);
  }

  /// Get the pagination cursor from the last request.
  String? get lastSearchNext => _lastSearchNext;

  /// Search with debounce (300ms). Returns a future that resolves after the delay.
  Future<List<TenorGif>> searchDebounced(
    String query, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    final completer = Completer<List<TenorGif>>();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () async {
      try {
        final results = await search(query);
        completer.complete(results);
      } catch (e) {
        completer.complete([]);
      }
    });
    return completer.future;
  }

  List<TenorGif> _parseResults(Map<String, dynamic> data) {
    final results = data['results'] as List? ?? [];
    return results
        .map((r) => TenorGif.fromJson(r as Map<String, dynamic>))
        .where((gif) => gif.thumbnailUrl.isNotEmpty && gif.gifUrl.isNotEmpty)
        .toList();
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}

final tenorServiceProvider = Provider<TenorService>((ref) {
  final service = TenorService(AppConfig.tenorApiKey);
  ref.onDispose(service.dispose);
  return service;
});
