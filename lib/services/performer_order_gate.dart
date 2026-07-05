import 'package:crgtransp72app/navigation/performer_active_order.dart';
import 'package:crgtransp72app/navigation/performer_shell_scope.dart';
import 'package:crgtransp72app/pages/zakaz_screen2.dart';
import 'package:flutter/material.dart';

enum PerformerStartBlockReason {
  none,
  otherOrderExecuting,
  reviewRequired,
}

class PerformerStartGate {
  final PerformerStartBlockReason reason;
  final PerformerActiveOrder? order;

  const PerformerStartGate({
    required this.reason,
    this.order,
  });

  static const allowed = PerformerStartGate(reason: PerformerStartBlockReason.none);

  bool get isBlocked => reason != PerformerStartBlockReason.none;

  String get message {
    switch (reason) {
      case PerformerStartBlockReason.otherOrderExecuting:
        return 'Сначала завершите текущий заказ. Начать новый нельзя, пока другой заказ выполняется.';
      case PerformerStartBlockReason.reviewRequired:
        return 'Оставьте или обновите отзыв о заказчике по завершённому заказу, прежде чем начинать новый.';
      case PerformerStartBlockReason.none:
        return '';
    }
  }

  /// Можно перейти к выполнению именно этой сделки (продолжить таймер).
  bool canStartForOffer({
    required String orderId,
    required String customerId,
  }) {
    if (!isBlocked || order == null) return true;

    final sameDeal = order!.orderId == orderId && order!.customerUserId == customerId;

    if (reason == PerformerStartBlockReason.otherOrderExecuting) {
      return sameDeal && order!.isExecuting;
    }
    if (reason == PerformerStartBlockReason.reviewRequired) {
      return false;
    }
    return true;
  }

  String buttonLabelForOffer({
    required String orderId,
    required String customerId,
    required bool offerAccepted,
    required bool dealExecuting,
  }) {
    if (canStartForOffer(orderId: orderId, customerId: customerId)) {
      if (dealExecuting || offerAccepted) {
        return 'Начать выполнение';
      }
      return 'Ожидает принятия заказчиком';
    }
    switch (reason) {
      case PerformerStartBlockReason.otherOrderExecuting:
        return 'Завершите текущий заказ';
      case PerformerStartBlockReason.reviewRequired:
        return 'Сначала оставьте отзыв';
      case PerformerStartBlockReason.none:
        return 'Начать выполнение';
    }
  }
}

Future<PerformerStartGate> fetchPerformerStartGate() async {
  final active = await fetchPerformerActiveOrder();
  if (active == null) {
    return PerformerStartGate.allowed;
  }
  if (active.isExecuting) {
    return PerformerStartGate(
      reason: PerformerStartBlockReason.otherOrderExecuting,
      order: active,
    );
  }
  return PerformerStartGate(
    reason: PerformerStartBlockReason.reviewRequired,
    order: active,
  );
}

Future<void> openPerformerOrdersTab(BuildContext context) async {
  final shellSelectTab = PerformerShellScope.selectTabOf(context);
  if (shellSelectTab != null) {
    shellSelectTab(1);
    return;
  }
  await Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const MyAppZakazScreen(initialPage: 1)),
    (route) => false,
  );
}

void showPerformerStartBlockedSnack(BuildContext context, PerformerStartGate gate) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(gate.message)),
  );
}
