/// Pagination metadata returned by list endpoints.
class PageMeta {
  final int total;
  final int limit;
  final int offset;

  const PageMeta({
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory PageMeta.fromJson(Map<String, dynamic> json) {
    return PageMeta(
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 50,
      offset: json['offset'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'limit': limit,
      'offset': offset,
    };
  }
}

/// Generic paginated response wrapper.
class PagedResponse<T> {
  final List<T> data;
  final PageMeta meta;

  const PagedResponse({
    required this.data,
    required this.meta,
  });
}
