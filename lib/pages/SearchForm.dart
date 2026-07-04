import 'package:crgtransp72app/pages/performer_search_screen.dart';
import 'package:flutter/material.dart';

/// Форма поиска исполнителя (вкладка «Заявки») → объявления заказчиков.
class SearchForm extends StatelessWidget {
  final bool showBottomNav;

  const SearchForm({super.key, this.showBottomNav = true});

  @override
  Widget build(BuildContext context) {
    return PerformerSearchScreen(showBottomNav: showBottomNav);
  }
}
