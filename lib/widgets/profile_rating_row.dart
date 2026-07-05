import 'package:crgtransp72app/pages/review_screen.dart';
import 'package:crgtransp72app/pages/review_screenz.dart';
import 'package:flutter/material.dart';

/// Рейтинг и счётчик отзывов под именем в профиле (как в ленте объявлений).
class ProfileRatingRow extends StatelessWidget {
  final double avgRating;
  final int reviewsCount;
  final VoidCallback onTap;

  const ProfileRatingRow({
    super.key,
    required this.avgRating,
    required this.reviewsCount,
    required this.onTap,
  });

  static double parseRating(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static int parseReviewsCount(dynamic value) {
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  /// Поля рейтинга из getuserinfo / getuserinfo_order (как в ленте поиска).
  static ({double avgRating, int reviewsCount}) fromApiMap(
    Map<String, dynamic> data,
  ) {
    return (
      avgRating: parseRating(data['avg_rating'] ?? data['rating']),
      reviewsCount: parseReviewsCount(
        data['reviewsCount'] ?? data['review_count'],
      ),
    );
  }

  /// Отзывы о заказчике (`reviews`).
  static void openCustomerReviews(BuildContext context, int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewScreen(
          userId: userId.toString(),
          showBottomNav: true,
        ),
      ),
    );
  }

  /// Отзывы об исполнителе (`reviewsisp`).
  static void openPerformerReviews(BuildContext context, int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewScreenz(
          userId: userId.toString(),
          showBottomNav: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < avgRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 16,
                );
              }),
            ),
            const SizedBox(width: 4),
            Text(
              avgRating.toStringAsFixed(1),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.comment_outlined, size: 16, color: Colors.grey),
            const SizedBox(width: 2),
            Text(
              '$reviewsCount',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
