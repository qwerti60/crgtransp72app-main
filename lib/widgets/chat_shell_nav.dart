import 'package:crgtransp72app/navigation/shell_bottom_nav_spec.dart';
import 'package:crgtransp72app/pages/customer_bottom_nav.dart';
import 'package:crgtransp72app/pages/performer_bottom_nav.dart';
import 'package:flutter/material.dart';

/// Нижнее меню на экранах чата/поддержки (вкладка «Профиль» активна).
Widget? chatShellBottomNav({
  required bool showBottomNav,
  required bool isPerformer,
}) {
  if (!showBottomNav) return null;
  const tabIndex = ShellTabBodyIds.profileTabIndex;
  if (isPerformer) {
    return PerformerBottomNav(currentIndex: tabIndex);
  }
  return CustomerBottomNav(currentIndex: tabIndex);
}
