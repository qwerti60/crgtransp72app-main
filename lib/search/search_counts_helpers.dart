/// Вспомогательные функции для UI счётчиков поиска.
library;

int searchLookupCount(Map<String, int> counts, String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 0;
  return counts[trimmed] ?? counts[name] ?? 0;
}

/// Услуги с ненулевым счётчиком — в начале списка.
List<Map<String, dynamic>> searchSortServicesByCount(
  List<Map<String, dynamic>> services,
  Map<String, int> serviceCounts,
) {
  final sorted = List<Map<String, dynamic>>.from(services);
  sorted.sort((a, b) {
    final nameA = (a['name'] ?? '').toString();
    final nameB = (b['name'] ?? '').toString();
    final ca = searchLookupCount(serviceCounts, nameA);
    final cb = searchLookupCount(serviceCounts, nameB);
    if (ca > 0 && cb == 0) return -1;
    if (ca == 0 && cb > 0) return 1;
    if (ca != cb) return cb.compareTo(ca);
    return nameA.compareTo(nameB);
  });
  return sorted;
}

/// Подсказка: в городе есть заявки/объявления, но не в выбранной категории.
String? searchOtherCategoriesHint({
  required bool isPerformer,
  required String? cityName,
  required Map<String, int> cityCounts,
  required Map<String, int> serviceCounts,
  List<String>? breakdownNames,
}) {
  if (cityName == null || cityName.trim().isEmpty) return null;

  final cityTotal = searchLookupCount(cityCounts, cityName);
  if (cityTotal <= 0) return null;

  final withCount = <String>[];
  if (breakdownNames != null && breakdownNames.isNotEmpty) {
    withCount.addAll(breakdownNames);
  } else {
    serviceCounts.forEach((name, count) {
      if (count > 0) withCount.add(name);
    });
  }

  if (withCount.isEmpty) return null;

  final noun = isPerformer ? 'заявк' : 'объявлен';
  final nounForm = cityTotal == 1 ? '$nounа' : '$nounи';
  final examples = withCount.take(3).join(', ');

  return 'В городе $cityTotal $nounForm — смотрите услуги с (1): $examples';
}
