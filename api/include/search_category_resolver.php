<?php
declare(strict_types=1);

/**
 * Единый resolver категории поиска (обёртки над search_services_core).
 * См. docs/search_future_ru.md §2.1
 */

require_once __DIR__ . '/search_services_core.php';

/**
 * @return array{bd:int,demand:string,supply:string,category_field:?string}|null
 */
function crg_resolve_search_category(mysqli $conn, string $nameImg, string $side): ?array
{
    if ($nameImg === '') {
        return null;
    }

    if ($side === 'supply') {
        return search_resolve_supply_category($conn, $nameImg);
    }

    if ($side === 'demand') {
        return search_resolve_demand_category($conn, $nameImg);
    }

    return null;
}

/**
 * @return array{bd:int,demand:string,supply:string,category_field:?string}|null
 */
function crg_bd_config(int $bd): ?array
{
    return search_bd_config_from_bd($bd);
}

function crg_is_gruzchik_service(mysqli $conn, string $nameImg): bool
{
    return search_is_gruzchik_service_name($conn, $nameImg);
}
