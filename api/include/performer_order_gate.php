<?php
/**
 * Исполнитель не может начать новую сделку, пока выполняется другой заказ
 * или не оставлен отзыв о заказчике по завершённому заказу.
 *
 * @return array<string,mixed>|null null — можно начинать; иначе code + message
 */
function crg_performer_may_start_new_deal(
    PDO $pdo,
    int $performerId,
    string $orderId,
    string $customerId
): ?array {
    if ($performerId <= 0) {
        return [
            'code' => 'invalid_user',
            'message' => 'Не указан исполнитель.',
        ];
    }

    $stmtExecuting = $pdo->prepare(
        "SELECT order_id, user_idok, status
         FROM ordersglobal
         WHERE user_id = :performerId AND status = 'выполняется'
         ORDER BY id DESC
         LIMIT 1"
    );
    $stmtExecuting->bindValue(':performerId', $performerId, PDO::PARAM_INT);
    $stmtExecuting->execute();
    $executing = $stmtExecuting->fetch(PDO::FETCH_ASSOC);

    if ($executing !== false) {
        $sameDeal = (string) $executing['order_id'] === $orderId
            && (string) $executing['user_idok'] === $customerId;
        if (!$sameDeal) {
            return [
                'code' => 'executing_other',
                'message' => 'Сначала завершите текущий заказ. Начать новый нельзя, пока другой заказ выполняется.',
                'order_id' => $executing['order_id'],
                'user_idok' => $executing['user_idok'],
                'status' => $executing['status'],
            ];
        }
    }

    $stmtCompleted = $pdo->prepare(
        "SELECT order_id, user_idok, status
         FROM ordersglobal
         WHERE user_id = :performerId AND status = 'выполнен'
         ORDER BY id DESC"
    );
    $stmtCompleted->bindValue(':performerId', $performerId, PDO::PARAM_INT);
    $stmtCompleted->execute();

    $stmtReview = $pdo->prepare(
        'SELECT COUNT(*) FROM reviews
         WHERE user_id = :performerId AND target_user_id = :customerId'
    );

    while ($completed = $stmtCompleted->fetch(PDO::FETCH_ASSOC)) {
        $customerIdInt = (int) ($completed['user_idok'] ?? 0);
        if ($customerIdInt <= 0) {
            continue;
        }

        $stmtReview->bindValue(':performerId', $performerId, PDO::PARAM_INT);
        $stmtReview->bindValue(':customerId', $customerIdInt, PDO::PARAM_INT);
        $stmtReview->execute();
        if ((int) $stmtReview->fetchColumn() > 0) {
            continue;
        }

        $sameDeal = (string) $completed['order_id'] === $orderId
            && (string) $completed['user_idok'] === $customerId;
        if ($sameDeal) {
            return [
                'code' => 'review_required',
                'message' => 'Оставьте или обновите отзыв о заказчике по завершённому заказу, прежде чем начинать новый.',
                'order_id' => $completed['order_id'],
                'user_idok' => $completed['user_idok'],
                'status' => $completed['status'],
            ];
        }

        return [
            'code' => 'review_required_other',
            'message' => 'Оставьте отзыв о заказчике по завершённому заказу, прежде чем начинать новый.',
            'order_id' => $completed['order_id'],
            'user_idok' => $completed['user_idok'],
            'status' => $completed['status'],
        ];
    }

    return null;
}

function crg_json_performer_start_blocked(array $block): void
{
    echo json_encode([
        'message' => 'Нельзя начать выполнение',
        'blocked' => true,
        'block_code' => $block['code'] ?? 'blocked',
        'block_message' => $block['message'] ?? 'Нельзя начать новый заказ.',
        'order_id' => $block['order_id'] ?? null,
        'user_idok' => $block['user_idok'] ?? null,
        'status' => $block['status'] ?? null,
    ], JSON_UNESCAPED_UNICODE);
}
