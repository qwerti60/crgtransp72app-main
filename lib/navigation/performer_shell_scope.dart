import 'package:flutter/material.dart';

/// Позволяет [PerformerBottomNav] на вложенных экранах переключать вкладки
/// основного shell ([zakaz_screen2]) без pushAndRemoveUntil и второго меню.
class PerformerShellScope extends InheritedWidget {
  const PerformerShellScope({
    super.key,
    required this.selectTab,
    required super.child,
  });

  final void Function(int tabIndex) selectTab;

  static void Function(int tabIndex)? selectTabOf(BuildContext context) {
    return context
        .findAncestorWidgetOfExactType<PerformerShellScope>()
        ?.selectTab;
  }

  @override
  bool updateShouldNotify(PerformerShellScope oldWidget) =>
      selectTab != oldWidget.selectTab;
}
