<?php
/**
 * Удаляет дубли в offer_data: оставляет последнее активное предложение
 * на пару (iduserp, iduser, bd). Запуск на сервере:
 *   php scripts/dedupe_offer_data.php
 */
require_once __DIR__ . '/../api/databd.php';

$pdo = new PDO(
    "mysql:host=$host;dbname=$dbname;charset=utf8mb4",
    $username,
    $password,
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

$countStmt = $pdo->query(
    'SELECT COUNT(*) FROM offer_data od1
     INNER JOIN offer_data od2
       ON od1.iduserp = od2.iduserp
      AND od1.iduser = od2.iduser
      AND od1.bd = od2.bd
      AND od1.id < od2.id
      AND (od1.status = 0 OR od1.status IS NULL)
      AND (od2.status = 0 OR od2.status IS NULL)'
);
$toDelete = (int) $countStmt->fetchColumn();

if ($toDelete === 0) {
    echo "Дублей offer_data не найдено.\n";
    exit(0);
}

$pdo->exec(
    'DELETE od1 FROM offer_data od1
     INNER JOIN offer_data od2
       ON od1.iduserp = od2.iduserp
      AND od1.iduser = od2.iduser
      AND od1.bd = od2.bd
      AND od1.id < od2.id
      AND (od1.status = 0 OR od1.status IS NULL)
      AND (od2.status = 0 OR od2.status IS NULL)'
);

echo "Удалено дублей offer_data: {$toDelete}\n";
