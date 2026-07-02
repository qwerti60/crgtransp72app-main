/// Кэш авторизации для нижнего меню — чтобы при push нового экрана
/// (города → исполнители, профиль → мои объявления) меню не мигало гостевым.
class CustomerShellNavCache {
  CustomerShellNavCache._();

  static bool resolved = false;
  static bool isAuthorized = false;
  static bool highlightOrders = false;
  static String activeOrderUserId = '';
  static String activeOrderId = '';

  static void update({
    required bool isAuthorized,
    required bool highlightOrders,
    required String activeOrderUserId,
    required String activeOrderId,
  }) {
    CustomerShellNavCache.isAuthorized = isAuthorized;
    CustomerShellNavCache.highlightOrders = highlightOrders;
    CustomerShellNavCache.activeOrderUserId = activeOrderUserId;
    CustomerShellNavCache.activeOrderId = activeOrderId;
    resolved = true;
  }

  static void clear() {
    resolved = false;
    isAuthorized = false;
    highlightOrders = false;
    activeOrderUserId = '';
    activeOrderId = '';
  }
}

class PerformerShellNavCache {
  PerformerShellNavCache._();

  static bool resolved = false;
  static bool isAuthorized = false;
  static bool highlightOrders = false;

  static void update({
    required bool isAuthorized,
    required bool highlightOrders,
  }) {
    PerformerShellNavCache.isAuthorized = isAuthorized;
    PerformerShellNavCache.highlightOrders = highlightOrders;
    resolved = true;
  }

  static void clear() {
    resolved = false;
    isAuthorized = false;
    highlightOrders = false;
  }
}
