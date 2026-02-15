/// Sentinel DateTime for the Unix epoch (1970-01-01T00:00:00Z).
/// Used as a fallback when date parsing fails and a non-null value is required.
DateTime epochUtc() => DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
