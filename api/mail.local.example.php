<?php
/**
 * Скопируйте этот файл в api/mail.local.php на сервере и укажите ваш ящик.
 * mail.local.php не коммитится — пароль остаётся только на хостинге.
 */

// Ящик, который вы создали в панели хостинга (отправитель):
$crg_mail_from = 'noreply@gruzoperevozki72.ru';

// Рег.ру: https://help.reg.ru/support/hosting/nastroyka-pochty-regru/...
// SMTP SSL/TLS: mail.hosting.reg.ru, порт 465
$crg_mail_smtp_enabled = true;
$crg_mail_smtp_host = 'mail.hosting.reg.ru';
$crg_mail_smtp_port = 465;
$crg_mail_smtp_secure = 'ssl'; // ssl (465) или tls (587 без SSL на старте)
$crg_mail_smtp_user = 'noreply@gruzoperevozki72.ru';
$crg_mail_smtp_pass = 'ПАРОЛЬ_ОТ_ПОЧТОВОГО_ЯЩИКА';

// Секрет для диагностики: откройте в браузере
// /api/mail_diag.php?key=ВАШ_СЕКРЕТ&to=ваш@email.ru
$crg_mail_diag_secret = 'crg-mail-diag';
