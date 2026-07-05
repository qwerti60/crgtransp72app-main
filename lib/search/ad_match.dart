import 'package:crgtransp72app/customer_ad_category.dart';
import 'package:crgtransp72app/design/colors.dart';
import 'package:crgtransp72app/models/search_params.dart';
import 'package:crgtransp72app/pages/outputob.dart';
import 'package:crgtransp72app/pages/outputobz.dart';
import 'package:flutter/material.dart';

/// Имя категории в справочнике gruzchik (getsearsh.php / getads3.php).
const String kGruzchikCategoryName = 'Грузчики';

String categoryNameFromBd(Map<String, dynamic> ad, int bd) {
  switch (bd) {
    case 2:
      final vidt = ad['vidt']?.toString().trim();
      if (vidt != null && vidt.isNotEmpty) return vidt;
      return '';
    case 3:
      return kGruzchikCategoryName;
    case 1:
    default:
      final maxgruz = ad['maxgruz']?.toString().trim();
      if (maxgruz != null && maxgruz.isNotEmpty) return maxgruz;
      return '';
  }
}

String categoryNameFromCustomerAd(Map<String, dynamic> ad) {
  return categoryNameFromBd(ad, bdFromCustomerAd(ad));
}

String categoryNameFromPerformerAd(Map<String, dynamic> ad) {
  return categoryNameFromBd(ad, bdFromPerformerAd(ad));
}

SearchParams searchParamsFromCustomerAd(Map<String, dynamic> ad) {
  final parts = <String>[
    ad['about']?.toString() ?? '',
    ad['vidk']?.toString() ?? '',
    ad['typepr']?.toString() ?? '',
    ad['zagr']?.toString() ?? '',
  ].where((s) => s.trim().isNotEmpty);

  return SearchParams(
    query: parts.join(' ').trim(),
    cityTo: ad['city1']?.toString().trim(),
    priceMax: ad['cena']?.toString().trim(),
    sort: 'relevance',
  );
}

/// Быстрый подбор с карточки «Мои объявления» — город + категория + бюджет, без текста.
SearchParams searchParamsFromCustomerAdMatch(Map<String, dynamic> ad) {
  return SearchParams(
    priceMax: ad['cena']?.toString().trim(),
    sort: 'relevance',
  );
}

SearchParams searchParamsFromPerformerAd(Map<String, dynamic> ad) {
  final parts = <String>[
    ad['marka']?.toString() ?? '',
    ad['vidk']?.toString() ?? '',
    ad['about']?.toString() ?? '',
    ad['maxgruz']?.toString() ?? '',
    ad['vidt']?.toString() ?? '',
  ].where((s) => s.trim().isNotEmpty);

  return SearchParams(
    query: parts.join(' ').trim(),
    sort: 'relevance',
  );
}

SearchParams searchParamsFromPerformerAdMatch(Map<String, dynamic> ad) {
  return const SearchParams(sort: 'relevance');
}

void openPerformersForCustomerAd(
  BuildContext context,
  Map<String, dynamic> ad,
) {
  final city = ad['city']?.toString().trim() ?? '';
  final category = categoryNameFromCustomerAd(ad);
  if (city.isEmpty || category.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('У объявления не указаны город или категория услуги'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  // Полноэкранный push + одно меню: иначе меню shell (MenuzakScreen / zakaz_screen1)
  // остаётся под результатами и получается двойная панель.
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      builder: (_) => outputob(
        nameImg: category,
        city: city,
        showBottomNav: true,
        customerBottomNavIndex: 2,
        useCustomerNavigation: true,
        searchParams: searchParamsFromCustomerAdMatch(ad),
        openSearchOnEmpty: true,
      ),
    ),
  );
}

void openOrdersForPerformerAd(
  BuildContext context,
  Map<String, dynamic> ad,
) {
  final city = ad['city']?.toString().trim() ?? '';
  final category = categoryNameFromPerformerAd(ad);
  if (city.isEmpty || category.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('У объявления не указаны город или категория услуги'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      builder: (_) => outputobz(
        nameImg: category,
        city: city,
        showBottomNav: true,
        performerBottomNavIndex: 2,
        searchParams: searchParamsFromPerformerAdMatch(ad),
        openSearchOnEmpty: true,
      ),
    ),
  );
}

/// Кнопка быстрого подбора в стиле приложения.
class AdMatchSearchButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AdMatchSearchButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          style: TextButton.styleFrom(
            fixedSize: const Size(double.infinity, 48),
            foregroundColor: whiteprColor,
            backgroundColor: blueaccentColor,
            disabledForegroundColor: grayprprColor,
            disabledBackgroundColor: grayprprColor.withValues(alpha: 0.5),
            shape: const BeveledRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(3)),
            ),
          ),
          onPressed: onPressed,
          child: Text(label),
        ),
      ),
    );
  }
}
