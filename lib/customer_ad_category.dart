/// Категория заявки заказчика: 1 — перевозки, 2 — спецтехника, 3 — грузчики.
int bdForCustomerAdTable(String? tableName) {
  switch (tableName) {
    case 'orderst':
      return 2;
    case 'ordersg':
      return 3;
    default:
      return 1;
  }
}

int bdFromCustomerAd(Map<String, dynamic> ad) {
  final fromApi = int.tryParse(ad['bd']?.toString() ?? '');
  if (fromApi != null && fromApi > 0) {
    return fromApi;
  }
  return bdForCustomerAdTable(ad['table_name']?.toString());
}

/// Категория объявления исполнителя: 1 — перевозки, 2 — спецтехника, 3 — грузчики.
int bdForPerformerAdTable(String? tableName) {
  switch (tableName) {
    case 'add_ob_vidt':
      return 2;
    case 'add_ob_gr':
      return 3;
    case 'add_ob_gp':
    default:
      return 1;
  }
}

int bdFromPerformerAd(Map<String, dynamic> ad) {
  final fromApi = int.tryParse(ad['bd']?.toString() ?? '');
  if (fromApi != null && fromApi > 0) {
    return fromApi;
  }
  return bdForPerformerAdTable(ad['tableName']?.toString());
}

/// bd по ответу get_cities.php (lookup_table / main_table).
int bdFromPerformerServiceMeta({
  String? lookupTable,
  String? mainTable,
}) {
  if (mainTable != null && mainTable.isNotEmpty) {
    return bdForCustomerAdTable(mainTable);
  }
  switch (lookupTable) {
    case 'vidt':
      return 2;
    case 'vidg':
      return 1;
    case 'gruzchik':
      return 3;
    default:
      return 1;
  }
}
