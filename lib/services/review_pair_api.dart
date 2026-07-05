import 'dart:convert';

import 'package:crgtransp72app/config.dart';
import 'package:http/http.dart' as http;

/// Отзыв исполнителя о заказчике (`reviews`).
enum ReviewPairTable { performerAboutCustomer, customerAboutPerformer }

class ExistingReview {
  final int rating;
  final String comment;

  const ExistingReview({required this.rating, required this.comment});
}

/// Загрузить существующий отзыв между исполнителем и заказчиком.
Future<ExistingReview?> fetchReviewBetween({
  required ReviewPairTable table,
  required int performerId,
  required int customerId,
}) async {
  if (performerId <= 0 || customerId <= 0) return null;

  final tableName = table == ReviewPairTable.performerAboutCustomer
      ? 'reviews'
      : 'reviewsisp';

  final uri = Uri.parse('${Config.baseUrl}/api/get_review_between.php').replace(
    queryParameters: {
      'table': tableName,
      'user_id': performerId.toString(),
      'target_user_id': customerId.toString(),
    },
  );

  try {
    final response =
        await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);
    if (data is! Map || data['found'] != true) return null;

    final rating = int.tryParse(data['rating']?.toString() ?? '') ?? 0;
    final comment = data['comment']?.toString() ?? '';
    if (rating <= 0 && comment.trim().isEmpty) return null;

    return ExistingReview(
      rating: rating.clamp(1, 5),
      comment: comment,
    );
  } catch (_) {
    return null;
  }
}
