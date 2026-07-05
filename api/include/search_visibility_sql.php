<?php
declare(strict_types=1);

/**
 * Единые SQL-фрагменты видимости для поиска (supply / demand).
 * См. docs/search_future_ru.md §2.2
 */

function crg_sql_demand_user_exists(string $orderAlias = 'a'): string
{
    $orderAlias = preg_replace('/[^a-zA-Z0-9_]/', '', $orderAlias);

    return "AND EXISTS (
        SELECT 1 FROM users u_exists
        WHERE u_exists.idusers = {$orderAlias}.iduser
    )";
}

function crg_sql_hide_active_deal_customer_order(int $bd, string $orderAlias = 'a'): string
{
    $bd = (int) $bd;
    $orderAlias = preg_replace('/[^a-zA-Z0-9_]/', '', $orderAlias);

    return "AND NOT EXISTS (
        SELECT 1 FROM offer_data od_busy
        WHERE od_busy.iduser = {$orderAlias}.id
          AND od_busy.bd = {$bd}
          AND od_busy.isp = 1
          AND (od_busy.status = 0 OR od_busy.status IS NULL)
    )
    AND NOT EXISTS (
        SELECT 1 FROM ordersglobal og
        WHERE CAST(og.order_id AS CHAR) = CAST({$orderAlias}.id AS CHAR)
          AND (og.bd IS NULL OR og.bd = {$bd} OR og.bd = 0)
          AND og.status = 'выполняется'
    )";
}

function crg_sql_hide_active_deal_performer_ad(int $bd, string $adAlias = 'a'): string
{
    $bd = (int) $bd;
    $adAlias = preg_replace('/[^a-zA-Z0-9_]/', '', $adAlias);

    return "AND NOT EXISTS (
        SELECT 1 FROM ordersglobal og
        INNER JOIN offer_dataf odf ON odf.id = og.idoffer AND odf.bd = {$bd}
        WHERE CAST(og.order_id AS CHAR) = CAST({$adAlias}.id AS CHAR)
          AND og.user_idok = ?
          AND og.status = 'выполняется'
    )";
}

/**
 * Базовые фильтры demand (заявки заказчика) — без города и категории.
 */
function crg_sql_demand_base_filters(int $bd, string $orderAlias = 'a'): string
{
    return crg_sql_demand_user_exists($orderAlias)
        . "\n          "
        . crg_sql_hide_active_deal_customer_order($bd, $orderAlias);
}

/**
 * Фильтры supply: активное объявление + сделка с viewer.
 */
function crg_sql_supply_base_filters(int $bd, string $adAlias = 'a'): string
{
    $adAlias = preg_replace('/[^a-zA-Z0-9_]/', '', $adAlias);

    return "AND ({$adAlias}.flag IS NULL OR {$adAlias}.flag = 1)\n          "
        . crg_sql_hide_active_deal_performer_ad($bd, $adAlias);
}
