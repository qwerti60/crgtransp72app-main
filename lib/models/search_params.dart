/// Параметры расширенного поиска (docs/search_logic_ru.md).
class SearchParams {
  final String? query;
  final String? cityTo;
  final String? priceMax;
  final String sort;

  /// Поиск только по строке (без обязательного города и услуги).
  final bool freeText;

  const SearchParams({
    this.query,
    this.cityTo,
    this.priceMax,
    this.sort = 'relevance',
    this.freeText = false,
  });

  bool get hasQuery => query != null && query!.trim().length >= 3;

  bool get isAdvanced =>
      freeText ||
      hasQuery ||
      (cityTo != null && cityTo!.trim().isNotEmpty) ||
      (priceMax != null && priceMax!.trim().isNotEmpty) ||
      sort != 'relevance';

  Map<String, String> toQueryParameters({
    required String role,
    required String nameImg,
    required String city,
    required int userId,
    bool allCities = false,
  }) {
    final trimmedQuery = query?.trim() ?? '';
    final useFreeText = freeText && trimmedQuery.length >= 3;

    return {
      'role': role,
      'useId': userId.toString(),
      'usersid': userId.toString(),
      if (useFreeText) 'free_text': '1',
      if (nameImg.trim().isNotEmpty) 'nameImg': nameImg.trim(),
      if (city.trim().isNotEmpty) 'city': city.trim(),
      if (allCities || (useFreeText && city.trim().isEmpty)) 'all_cities': '1',
      if (trimmedQuery.isNotEmpty) 'q': trimmedQuery,
      if (cityTo != null && cityTo!.trim().isNotEmpty) 'city_to': cityTo!.trim(),
      if (priceMax != null && priceMax!.trim().isNotEmpty)
        'price_max': priceMax!.trim(),
      'sort': sort,
      'limit': '50',
    };
  }
}

const List<SearchSortOption> kSearchSortOptions = [
  SearchSortOption('relevance', 'По релевантности'),
  SearchSortOption('rating', 'По рейтингу'),
  SearchSortOption('price', 'По цене'),
  SearchSortOption('date', 'По дате'),
];

class SearchSortOption {
  final String value;
  final String label;

  const SearchSortOption(this.value, this.label);
}
