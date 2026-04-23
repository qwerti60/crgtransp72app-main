import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl; // URL, полученный с бэка

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true; // индикатор загрузки

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          // Перехватываем переходы
          onNavigationRequest: _handleNavigationRequest,

          // Страница полностью загрузилась
          onPageFinished: _handlePageFinished,

          // Если нужна обработка ошибок загрузки:
          onWebResourceError: (WebResourceError error) {
            debugPrint(
              'WebView error: ${error.errorCode} | ${error.description}',
            );
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  // onPageFinished
  void _handlePageFinished(String url) {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // onNavigationRequest
  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    // Пример: если банк возвращает intent://... – закрываем экран
    if (request.url.contains('intent://')) {
      Navigator.of(context).pop(); // закрываем экран
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Оплата')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),

          // Индикатор загрузки поверх WebView
          if (_isLoading)
            const Positioned.fill(
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
