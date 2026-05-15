/// Единое описание нижнего меню для заказчика / исполнителя и гостя / авторизованного.
/// Используется в UI и в unit-тестах, чтобы подписи и количество вкладок не расходились между файлами.
///
/// **Как расширять:** для нового экрана с `BottomNavigationBar`
/// 1. Добавьте сюда класс `*ShellNav` с методом `bottomNavLabels` и комментарием с именем файла/виджета.
/// 2. В виджете подставьте подписи из этого класса (как в `zakaz_screen1.dart`).
/// 3. В `test/shell_bottom_nav_spec_test.dart` добавьте проверки; если подписи близки к другой ветке
///    (например «Заказы» vs «Заявки»), обязательно зафиксируйте отличие тестом.

/// Подписи вкладок основного shell заказчика (`zakaz_screen1`, `customer_bottom_nav`, `menuzak`).
class CustomerShellNav {
  CustomerShellNav._();

  static const String tabServices = 'Услуги';
  static const String tabOrders = 'Заказы';
  static const String tabProfile = 'Профиль';

  /// Гость: 2 вкладки; авторизованный: 3.
  static List<String> bottomNavLabels({required bool isAuthenticated}) =>
      isAuthenticated
          ? const [tabServices, tabOrders, tabProfile]
          : const [tabServices, tabOrders];
}

/// Подписи вкладок основного shell исполнителя (`zakaz_screen2`, `performer_bottom_nav`).
class PerformerShellNav {
  PerformerShellNav._();

  static const String tabListings = 'Объявления';
  static const String tabApplications = 'Заявки';
  static const String tabProfile = 'Профиль';

  static List<String> bottomNavLabels({required bool isAuthenticated}) =>
      isAuthenticated
          ? const [tabListings, tabApplications, tabProfile]
          : const [tabListings, tabApplications];
}

/// Альтернативная оболочка исполнителя `HistortScreen` в `test.dart` — всегда три вкладки.
class PerformerHistortShellNav {
  PerformerHistortShellNav._();

  static List<String> bottomNavLabels() => const [
        PerformerShellNav.tabListings,
        PerformerShellNav.tabApplications,
        PerformerShellNav.tabProfile,
      ];
}

/// `bmenu.dart` / `HistortScreen12`: вторая вкладка «Заказы», не «Заявки».
class PerformerBmenuShellNav {
  PerformerBmenuShellNav._();

  static const String tabListings = PerformerShellNav.tabListings;
  static const String tabOrders = 'Заказы';
  static const String tabProfile = PerformerShellNav.tabProfile;

  static List<String> bottomNavLabels({required bool isAuthenticated}) =>
      isAuthenticated
          ? const [tabListings, tabOrders, tabProfile]
          : const [tabListings, tabOrders];
}

/// `bmenucopy.dart` — всегда три вкладки (середина «Заказы»).
class PerformerBmenuCopyShellNav {
  PerformerBmenuCopyShellNav._();

  static List<String> bottomNavLabels() => const [
        PerformerBmenuShellNav.tabListings,
        PerformerBmenuShellNav.tabOrders,
        PerformerBmenuShellNav.tabProfile,
      ];
}

/// Устаревший `profil_page.dart` (`profil_name`): «Техника», «Заказы», «Профиль».
class LegacyProfilPageBottomNav {
  LegacyProfilPageBottomNav._();

  static const String tabEquipment = 'Техника';
  static const String tabOrders = 'Заказы';
  static const String tabProfile = 'Профиль';

  static List<String> bottomNavLabels() =>
      const [tabEquipment, tabOrders, tabProfile];
}

/// Стабильные идентификаторы тел экрана по индексу вкладки (для тестов и ревью навигации).
class ShellTabBodyIds {
  ShellTabBodyIds._();

  static String customer(int tabIndex, {required bool isAuthenticated}) {
    switch (tabIndex) {
      case 0:
        return 'customer_services_grid';
      case 1:
        return 'customer_orders_hub';
      case 2:
        if (!isAuthenticated) {
          return 'customer_guest_profile_ads1_placeholder';
        }
        return 'customer_profile_zprofil_name';
      default:
        return 'customer_services_grid';
    }
  }

  static String performer(int tabIndex, {required bool isAuthenticated}) {
    switch (tabIndex) {
      case 0:
        return 'performer_services_grid';
      case 1:
        return 'performer_orders_hub';
      case 2:
        if (!isAuthenticated) {
          return 'performer_guest_profile_ads2_placeholder';
        }
        return 'performer_profile_zprofil_name2';
      default:
        return 'performer_services_grid';
    }
  }

  static const int profileTabIndex = 2;

  static int clampTabIndex(int requested, int tabCount) {
    if (tabCount <= 0) return 0;
    if (requested < 0) return 0;
    if (requested >= tabCount) return 0;
    return requested;
  }
}
