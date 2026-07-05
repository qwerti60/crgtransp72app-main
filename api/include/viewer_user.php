<?php
/**
 * Id залогиненного пользователя из GET/POST (useId, usersid, user_id).
 */
function crg_viewer_user_id_from_request(array $params): int
{
    foreach (['useId', 'usersid', 'user_id'] as $key) {
        if (!isset($params[$key])) {
            continue;
        }
        $raw = trim((string) $params[$key]);
        if ($raw === '' || $raw === '0') {
            continue;
        }
        $id = (int) $raw;
        if ($id > 0) {
            return $id;
        }
    }

    return 0;
}

/**
 * Запрет отклика самому себе (POST без фильтров поиска).
 */
function crg_forbid_self_offer(int $viewerId, int $adOwnerId): void
{
    if ($viewerId > 0 && $adOwnerId > 0 && $viewerId === $adOwnerId) {
        http_response_code(403);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(
            ['status' => 'error', 'message' => 'Cannot offer on your own ad'],
            JSON_UNESCAPED_UNICODE
        );
        exit;
    }
}

/**
 * SQL-фрагмент: не показывать объявления, где владелец = текущий пользователь.
 */
function crg_sql_exclude_self_supply(string $alias = 'a'): string
{
    return "AND {$alias}.iduser IS NOT NULL AND CAST({$alias}.iduser AS CHAR) != CAST(? AS CHAR)";
}
