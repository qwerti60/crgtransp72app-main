import 'package:crgtransp72app/navigation/shell_bottom_nav_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Customer shell bottom nav', () {
    test('guest has exactly Услуги + Заказы', () {
      final labels =
          CustomerShellNav.bottomNavLabels(isAuthenticated: false);
      expect(labels, ['Услуги', 'Заказы']);
      expect(labels.length, 2);
    });

    test('authorized adds Профиль', () {
      final labels =
          CustomerShellNav.bottomNavLabels(isAuthenticated: true);
      expect(labels, ['Услуги', 'Заказы', 'Профиль']);
    });
  });

  group('Performer main shell bottom nav', () {
    test('guest has Объявления + Заявки', () {
      final labels =
          PerformerShellNav.bottomNavLabels(isAuthenticated: false);
      expect(labels, ['Объявления', 'Заявки']);
    });

    test('authorized adds Профиль', () {
      final labels =
          PerformerShellNav.bottomNavLabels(isAuthenticated: true);
      expect(labels, ['Объявления', 'Заявки', 'Профиль']);
    });
  });

  group('Performer Histort shell', () {
    test('always three tabs (profile visible)', () {
      final labels = PerformerHistortShellNav.bottomNavLabels();
      expect(labels.length, 3);
      expect(labels[2], 'Профиль');
    });
  });

  group('Branches do not share customer vs performer wording', () {
    test('first tab differs between roles', () {
      final c =
          CustomerShellNav.bottomNavLabels(isAuthenticated: true).first;
      final p =
          PerformerShellNav.bottomNavLabels(isAuthenticated: true).first;
      expect(c, isNot(equals(p)));
      expect(c, 'Услуги');
      expect(p, 'Объявления');
    });
  });

  group('Legacy profil_page bottom bar', () {
    test('always Техника / Заказы / Профиль', () {
      expect(LegacyProfilPageBottomNav.bottomNavLabels(),
          ['Техника', 'Заказы', 'Профиль']);
    });
  });

  group('Performer bmenu (middle tab is Заказы, not Заявки)', () {
    test('differs from main performer shell middle label', () {
      final bmenuAuth =
          PerformerBmenuShellNav.bottomNavLabels(isAuthenticated: true);
      final mainAuth =
          PerformerShellNav.bottomNavLabels(isAuthenticated: true);
      expect(bmenuAuth[1], 'Заказы');
      expect(mainAuth[1], 'Заявки');
    });

    test('guest has two tabs', () {
      expect(
        PerformerBmenuShellNav.bottomNavLabels(isAuthenticated: false).length,
        2,
      );
    });
  });

  group('Performer bmenucopy', () {
    test('always three tabs with Заказы in the middle', () {
      final labels = PerformerBmenuCopyShellNav.bottomNavLabels();
      expect(labels, ['Объявления', 'Заказы', 'Профиль']);
    });
  });

  group('ShellTabBodyIds — guest vs auth profile slot', () {
    test('customer tab 2: guest placeholder ≠ auth profile', () {
      final guest = ShellTabBodyIds.customer(2, isAuthenticated: false);
      final auth = ShellTabBodyIds.customer(2, isAuthenticated: true);
      expect(guest, 'customer_guest_profile_ads1_placeholder');
      expect(auth, 'customer_profile_zprofil_name');
      expect(guest, isNot(equals(auth)));
    });

    test('performer tab 2: guest placeholder ≠ auth profile', () {
      final guest = ShellTabBodyIds.performer(2, isAuthenticated: false);
      final auth = ShellTabBodyIds.performer(2, isAuthenticated: true);
      expect(guest, 'performer_guest_profile_ads2_placeholder');
      expect(auth, 'performer_profile_zprofil_name2');
    });

    test('clampTabIndex avoids out-of-range for 2-tab guest bar', () {
      expect(ShellTabBodyIds.clampTabIndex(5, 2), 0);
      expect(ShellTabBodyIds.clampTabIndex(1, 2), 1);
    });
  });
}
