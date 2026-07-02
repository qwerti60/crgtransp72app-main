# Веб-админка CRG Transp72

## Руководства

| Кому | Где |
|------|-----|
| **Менеджеру** (модерация, без техники) | В админке: **Руководство** → [`docs/admin_manager_guide.md`](admin_manager_guide.md) |
| **Разработчику** (установка, БД, API) | В админке: **Техническое** → [`docs/admin_guide.md`](admin_guide.md) |

## Быстрый старт (разработка)

```bash
mysql --default-character-set=utf8mb4 -u root < sql/local_dev.sql
mysql --default-character-set=utf8mb4 -u root crg_local < sql/migrate_admin_users_ads.sql
./scripts/seed_test_ads.sh
cd api && php -S 127.0.0.1:8080
```

Вход: http://127.0.0.1:8080/admin-web/login.php — `admin` / `ChangeMe_Admin1!`
