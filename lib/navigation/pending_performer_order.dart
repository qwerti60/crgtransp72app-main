/// Одноразовый контекст заказа при переходе «Начать выполнение» → вкладка Заказы.
class PendingPerformerOrder {
  PendingPerformerOrder._();

  static String? performerId;
  static String? orderId;
  static String? customerUserId;
  static int? bd;
  /// customer_order — отклик на заявку заказчика; performer_ad — заявка на объявление исполнителя.
  static String orderSource = 'customer_order';

  static void set({
    required String performer,
    required String order,
    required String customer,
    int? orderBd,
    String source = 'customer_order',
  }) {
    performerId = performer;
    orderId = order;
    customerUserId = customer;
    bd = orderBd;
    orderSource = source;
  }

  static bool get has =>
      (performerId ?? '').isNotEmpty && (orderId ?? '').isNotEmpty;

  static void clear() {
    performerId = null;
    orderId = null;
    customerUserId = null;
    bd = null;
    orderSource = 'customer_order';
  }
}
