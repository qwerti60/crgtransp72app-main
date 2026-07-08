<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';

$error = '';
$info = '';

if (isset($_GET['reset']) && (string) $_GET['reset'] === '1') {
    $info = 'Пароль изменён. Войдите с новым паролем.';
}
if (isset($_GET['pw']) && (string) $_GET['pw'] === '1') {
    $info = 'Пароль изменён. Войдите снова.';
}

tp_admin_web_redirect_if_logged_in();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    tp_admin_web_require_include('admin_login_verify.php');
    $login = (string) ($_POST['login'] ?? '');
    $password = (string) ($_POST['password'] ?? '');
    $pdo = tp_pdo();
    $result = tp_admin_perform_login($pdo, $login, $password);
    if ($result['ok'] === true) {
        session_regenerate_id(true);
        $_SESSION['admin_web_token'] = $result['token'];
        $_SESSION['admin_web_login'] = $result['login'];
        header('Location: stats.php', true, 302);
        exit;
    }
    $error = (string) $result['message'];
}

header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Вход администратора</title>
    <link rel="icon" type="image/png" href="assets/favicon.png">
    <style>
        body { font-family: system-ui, sans-serif; max-width: 28rem; margin: 2rem auto; padding: 0 1rem; }
        .login-logo {
            display: block;
            width: min(12rem, 80vw);
            height: auto;
            margin: 0 auto 1.25rem;
            background: #fff;
            border-radius: 12px;
            padding: 10px 14px;
            box-shadow: 0 1px 4px rgba(15, 23, 42, 0.12);
        }
        h1 { font-size: 1.25rem; text-align: center; }
        label { display: block; margin-top: 1rem; font-weight: 600; }
        input[type=text], input[type=password] { width: 100%; box-sizing: border-box; padding: 0.5rem; margin-top: 0.25rem; }
        button { margin-top: 1.25rem; padding: 0.5rem 1rem; cursor: pointer; }
        .err { color: #b00020; margin-top: 1rem; }
        .meta { color: #64748b; font-size: 0.85rem; margin-top: 1.5rem; }
    </style>
</head>
<body>
    <img class="login-logo" src="assets/logo.png" alt="Грузоперевозки72" width="189" height="127">
    <h1>Вход администратора</h1>
    <?php if ($error !== '') { ?>
        <p class="err"><?= tp_admin_web_h($error) ?></p>
    <?php } ?>
    <?php if ($info !== '') { ?>
        <p class="info" style="color:#15803d;margin-top:1rem"><?= tp_admin_web_h($info) ?></p>
    <?php } ?>
    <form method="post" action="login.php" autocomplete="off">
        <label for="login">Логин</label>
        <input id="login" name="login" type="text" required maxlength="64" value="">
        <label for="password">Пароль</label>
        <input id="password" name="password" type="password" required maxlength="256" value="">
        <button type="submit">Войти</button>
    </form>
    <p class="meta" style="margin-top:1.25rem"><a href="login_reset.php">Забыли пароль? Сброс по коду из e-mail</a></p>
    <p class="meta">Первый вход: логин <code>admin</code>, пароль <code>ChangeMe_Admin1!</code> (после миграции SQL). Укажите e-mail и смените пароль в разделе «Настройки».</p>
</body>
</html>
