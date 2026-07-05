<?php

/**
 * Сделка ordersglobal по объявлению заказчика (order_id = id заявки, user_idok = id заказчика).
 */
function crg_sql_customer_ad_bd_filter(int $bd, string $ogAlias = 'og'): string
{
    return " AND ({$ogAlias}.bd IS NULL OR {$ogAlias}.bd = {$bd} OR {$ogAlias}.bd = 0)";
}

/**
 * Подзапрос: статус последней сделки по объявлению заказчика.
 */
function crg_sql_customer_ad_order_status(string $adIdColumn, int $bd, string $customerIdColumn): string
{
    $bdFilter = crg_sql_customer_ad_bd_filter($bd);

    return "(SELECT og.status
        FROM ordersglobal og
        WHERE CAST(og.order_id AS CHAR) = CAST({$adIdColumn} AS CHAR)
          AND CAST(og.user_idok AS CHAR) = CAST({$customerIdColumn} AS CHAR)
          {$bdFilter}
          AND og.status IN ('выполняется', 'выполнен', 'отменен')
        ORDER BY
            CASE og.status
                WHEN 'выполняется' THEN 0
                WHEN 'выполнен' THEN 1
                ELSE 2
            END,
            og.id DESC
        LIMIT 1) AS order_status";
}

/**
 * 1 — объявление активно; 0 — заказ выполняется (новые отклики недоступны).
 * После «выполнен» / «отменен» объявление снова принимает предложения.
 */
function crg_sql_customer_ad_is_active(string $adIdColumn, int $bd, string $customerIdColumn): string
{
    $bdFilter = crg_sql_customer_ad_bd_filter($bd);

    return "(SELECT CASE
            WHEN EXISTS (
                SELECT 1 FROM ordersglobal og
                WHERE CAST(og.order_id AS CHAR) = CAST({$adIdColumn} AS CHAR)
                  AND CAST(og.user_idok AS CHAR) = CAST({$customerIdColumn} AS CHAR)
                  {$bdFilter}
                  AND og.status = 'выполняется'
            ) THEN 0
            ELSE 1
        END) AS is_active";
}

/**
 * id исполнителя текущей сделки (только пока заказ выполняется).
 */
function crg_sql_customer_ad_chosen_performer(string $adIdColumn, int $bd, string $customerIdColumn): string
{
    $bdFilter = crg_sql_customer_ad_bd_filter($bd);

    return "(SELECT og.user_id
        FROM ordersglobal og
        WHERE CAST(og.order_id AS CHAR) = CAST({$adIdColumn} AS CHAR)
          AND CAST(og.user_idok AS CHAR) = CAST({$customerIdColumn} AS CHAR)
          {$bdFilter}
          AND og.status = 'выполняется'
        ORDER BY og.id DESC
        LIMIT 1) AS chosen_performer_id";
}
