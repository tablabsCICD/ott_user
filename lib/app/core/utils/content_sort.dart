import 'package:ott/data/models/content.dart';

/// Returns [items] ordered newest first.
///
/// Uses the content's upload timestamp (`uploadDateTime`, when it was added
/// to Filmytell). Items without it fall back to their release date, and ties
/// fall back to the higher id (newer record). The input list is not modified.
List<Content> sortContentNewestFirst(List<Content> items) {
  final sorted = List<Content>.of(items);
  sorted.sort((a, b) {
    final byDate = _sortTimestamp(b).compareTo(_sortTimestamp(a));
    if (byDate != 0) return byDate;
    return (b.id ?? 0).compareTo(a.id ?? 0);
  });
  return sorted;
}

int _sortTimestamp(Content content) {
  final uploaded = _toMillis(content.uploadDateTime);
  if (uploaded > 0) return uploaded;
  return _toMillis(content.releaseDate);
}

int _toMillis(dynamic value) {
  if (value == null) return 0;
  if (value is DateTime) return value.millisecondsSinceEpoch;
  if (value is num) {
    final n = value.toInt();
    if (n <= 0) return 0;
    // Treat values below year-5138 seconds as epoch seconds.
    return n > 100000000000 ? n : n * 1000;
  }
  final text = value.toString().trim();
  if (text.isEmpty) return 0;
  final numeric = int.tryParse(text);
  if (numeric != null) return _toMillis(numeric);
  return DateTime.tryParse(text)?.millisecondsSinceEpoch ?? 0;
}
