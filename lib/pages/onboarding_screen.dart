import 'package:crgtransp72app/design/colors.dart';
import 'package:crgtransp72app/services/onboarding_service.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  final int rollNum;
  final VoidCallback onFinished;

  const OnboardingScreen({
    super.key,
    required this.rollNum,
    required this.onFinished,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  bool get _isCustomer => widget.rollNum == 1;

  late final List<_OnboardStep> _steps = _isCustomer
      ? const [
          _OnboardStep(
            icon: Icons.person_outline,
            title: 'Заполните профиль',
            body:
                'Укажите город и контакты — так исполнители быстрее найдут ваши заявки.',
          ),
          _OnboardStep(
            icon: Icons.post_add_outlined,
            title: 'Создайте первую заявку',
            body:
                'Опишите задачу, бюджет и срок. Чем точнее заявка — тем лучше отклики.',
          ),
          _OnboardStep(
            icon: Icons.handshake_outlined,
            title: 'Как устроена сделка',
            body:
                'Выберите исполнителя → общайтесь в чате → подтвердите выполнение и оставьте отзыв.',
          ),
        ]
      : const [
          _OnboardStep(
            icon: Icons.verified_user_outlined,
            title: 'Профиль исполнителя',
            body:
                'Добавьте фото, технику и тарифы. Активная подписка открывает заявки заказчиков.',
          ),
          _OnboardStep(
            icon: Icons.campaign_outlined,
            title: 'Объявление в каталоге',
            body:
                'Разместите транспорт или услугу — заказчики увидят вас в поиске по городу.',
          ),
          _OnboardStep(
            icon: Icons.route_outlined,
            title: 'Отклик → сделка',
            body:
                'Откликайтесь на заявки, ведите переписку, отмечайте «в пути» и завершайте заказ.',
          ),
        ];

  Future<void> _finish() async {
    await OnboardingService.markCompleted();
    if (!mounted) return;
    widget.onFinished();
  }

  void _next() {
    if (_page >= _steps.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteprColor,
      appBar: AppBar(
        backgroundColor: blueaccentColor,
        foregroundColor: whiteprColor,
        title: const Text('Добро пожаловать'),
        actions: [
          TextButton(
            onPressed: _finish,
            child: const Text('Пропустить', style: TextStyle(color: whiteprColor)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _steps.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, index) {
                final step = _steps[index];
                return Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(step.icon, size: 72, color: blueaccentColor),
                      const SizedBox(height: 24),
                      Text(
                        step.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        step.body,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, height: 1.45),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _steps.length,
              (i) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _page ? blueaccentColor : Colors.grey.shade300,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: blueaccentColor,
                  foregroundColor: whiteprColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _next,
                child: Text(
                  _page >= _steps.length - 1 ? 'Начать работу' : 'Далее',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardStep {
  final IconData icon;
  final String title;
  final String body;

  const _OnboardStep({
    required this.icon,
    required this.title,
    required this.body,
  });
}
