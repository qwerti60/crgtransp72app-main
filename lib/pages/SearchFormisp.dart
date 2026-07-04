import 'package:crgtransp72app/pages/customer_search_screen.dart';
import 'package:flutter/material.dart';

/// Форма поиска заказчика (вкладка «Заказы») → объявления исполнителей.
class SearchFormisp extends StatelessWidget {
  final bool embedInCustomerShell;

  const SearchFormisp({super.key, this.embedInCustomerShell = false});

  @override
  Widget build(BuildContext context) {
    return CustomerSearchScreen(embedInCustomerShell: embedInCustomerShell);
  }
}
