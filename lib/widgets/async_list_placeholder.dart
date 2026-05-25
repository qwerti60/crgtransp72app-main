import 'package:flutter/material.dart';

/// Замена паттерна `list.isEmpty ? CircularProgressIndicator()` — иначе спиннер бесконечный при ошибке API.
class AsyncListPlaceholder extends StatelessWidget {
  const AsyncListPlaceholder({
    super.key,
    required this.isLoading,
    required this.loadFailed,
    required this.isEmpty,
    required this.child,
    this.onRetry,
    this.emptyMessage = 'Нет данных',
    this.failedMessage = 'Не удалось загрузить данные',
  });

  final bool isLoading;
  final bool loadFailed;
  final bool isEmpty;
  final Widget child;
  final VoidCallback? onRetry;
  final String emptyMessage;
  final String failedMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (loadFailed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(failedMessage, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 8),
                TextButton(onPressed: onRetry, child: const Text('Повторить')),
              ],
            ],
          ),
        ),
      );
    }
    if (isEmpty) {
      return Center(
        child: Text(emptyMessage, textAlign: TextAlign.center),
      );
    }
    return child;
  }
}
