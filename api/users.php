<?php

    include("../include/adjustment.php");
    $conn=sql_connect();

$action = $_GET["action"];
$rollNum = $_GET["rollNum"];
$statNum = $_GET["statNum"];
if (isset($_GET["rollNum2"])) {
    $rollNum2 = $_GET["rollNum2"];
} else $rollNum2=null;
if (isset($_GET["flag"])) {
    $flag = $_GET["flag"];
} else $flag=null;

    $error = '';
    
    if($action == 'delete')
    {
        $id_user = $HTTP_GET_VARS["id_user"];
        $choice = "delete from users where id_user='" . $id_user . "'";
        if(@mysql_query($choice))
            $error = 'Пользователь удален';
	    $action='list';
    }
    if($action == 'update')
    {
        $name_firm = $HTTP_POST_VARS["name_firm"];
        $user_name = $HTTP_POST_VARS["user_name"];
        $e_mail = $HTTP_POST_VARS["e_mail"];
        $www = $HTTP_POST_VARS["www"];
        $icq = $HTTP_POST_VARS["icq"];
        $login = $HTTP_POST_VARS["login"];
        $password1 = $HTTP_POST_VARS["password1"];
        $password2 = $HTTP_POST_VARS["password2"];
        $info_registration = $HTTP_POST_VARS["info_registration"];
        #$user_status = $HTTP_POST_VARS["user_status"];

        $result = mysql_query("update users set name_firm='$name_firm', user_name='$user_name', telephone='$telephone', e_mail='$e_mail', www='$www', icq='$icq', login='$login', password='$password1', info_registration='$info_registration' where id_user= '$id_user'");
        $error = 'Информация о пользователе изменена';
        $action='list';	
    }
    if($action == 'insert')
    {
        $name_firm = $HTTP_POST_VARS["name_firm"];
        $user_name = $HTTP_POST_VARS["user_name"];
        $e_mail = $HTTP_POST_VARS["e_mail"];
        $www = $HTTP_POST_VARS["www"];
        $icq = $HTTP_POST_VARS["icq"];
        $login = $HTTP_POST_VARS["login"];
        $password1 = $HTTP_POST_VARS["password1"];
        $password2 = $HTTP_POST_VARS["password2"];
        $info_registration = $HTTP_POST_VARS["info_registration"];
        $i = 0;
        if(!$user_name)
        {
            if($i)
                $error .= ',';
            $i++;
            $error .= ' "ФИО"';
        }
        if(!$e_mail)
        {
            if($i)
                $error .= ',';
            $i++;
            $error .= ' "E-mail"';
        }
        if(!$login)
        {
            if($i)
                $error .= ',';
            $i++;
            $error .= ' "Логин"';
        }
        if($i == 1)
            $error = 'Поле' . $error . ' не может быть пустым. ';
        if($i > 1)
            $error = 'Поля' . $error . ' не могут быть пустыми. ';

        if($password1 != $password2)
        {
            $error .= 'Не совпадают поля "Пароль" и "Повтор пароля". ';
            $i++;
        }
        elseif(strlen($password1) < 6 && !(session_is_registered('session_id_user') && !$password1))
        {
            $error .= 'Поле "Пароль" должно содержать не меньше 6 символов';
            $i++;
        }
        elseif(!session_is_registered('session_id_user'))
        {
            if($i == 0)
            {
                $choice = "select id_user from temp_users where login='" . $login . "'";
                $result = mysql_query($choice);
                $num = mysql_num_rows($result);
                $choice = "select id_user from users where login='" . $login . "'";
                $result = mysql_query($choice);
                $num += mysql_num_rows($result);
                if($num)
                {
                    $error = 'Пользователь с таким логином уже есть';
                    $i++;
                }
            }
        }
	$error1=$error;
        if(!$error)
        {
  	    $choice = "insert into users set name_firm='" . $name_firm . "', user_name='" . $user_name . "', telephone='" . $telephone . "', e_mail='" . $e_mail . "', www='" . $www . "', icq='" . $icq . "', login='" . $login . "', password='" . $password1 . "', info_registration='" . $info_registration . "'";
              if(@mysql_query($choice))
              {
                  $error = 'Новый пользователь добавлен';
                  $name_firm = '';
                  $user_name = '';
                  $telephone = '';
                  $e_mail = '';
                  $www = '';
                  $icq = '';
                  $login = '';
                  $info_registration = '';
		  $action='list'; 
              }
        }
        if($error1){
            $error .= '<br><br>';
	    $action='edit';}
    }

    if($action == 'edit')
    {
        $id_user = $HTTP_GET_VARS["id_user"];
        if(!$id_user){
            $name_firm = "";
            $user_name = "";
            $e_mail = "";
            $www = "";
            $icq ="";
            $login = "";
            $password1 = "";
            $password2 = "";
            $info_registration = "";
            $button = 'Добавить пользователя';
	    $action='insert';
	}else{
          $choice = "select * from users where id_user='" . $id_user . "'";
          $result = mysql_query($choice);
          $num = mysql_num_rows($result);
          if($num)
          {
            $name_firm = mysql_result($result, 0, 'name_firm');
            $id_user = mysql_result($result, 0, 'id_user');
            $user_name = mysql_result($result, 0, 'user_name');
            $telephone = mysql_result($result, 0, 'telephone');
            $e_mail = mysql_result($result, 0, 'e_mail');
            $www = mysql_result($result, 0, 'www');
            $icq = mysql_result($result, 0, 'icq');
            $login = mysql_result($result, 0, 'login');
            $password = mysql_result($result, 0, 'password');
            $info_registration = mysql_result($result, 0, 'info_registration');
            $button = 'Изменить информацию пользователя';
	    $action='update';
         }
	}#else
?>
    <form action = "users.php?action=<?php echo $action; ?>&id_user=<?php echo $id_user; ?>" method = "post">
        <table width="99%" border="0" valign=top cellpadding="0" cellspacing="0">
            <tr><td colspan=3 class="text"><?php echo $error; ?></td></tr>
            <tr><td height=10 colspan=3></td></tr>
            <tr><td height=10 colspan=3 class=text align=center><b><?php echo $button; ?></b></td></tr>
            <tr><td height=10 colspan=3></td></tr>
            <tr><td height=10 colspan=3 class=text><b>* отмечены поля обязательные для ввода </b></td></tr>
            <tr><td height=10 colspan=3></td></tr>
            <tr><td width=25% valign=center align=right><font class="text">Фирма :&nbsp; &nbsp;</font></td>
                <td width=65% valign=top align=left colspan=2><input class="text" name="name_firm" type="text" value="<?php echo $name_firm; ?>" size="30" maxlength="20" style="BACKGROUND: #ffffff; HEIGHT: 17px; WIDTH: 275px"></td></tr>
            <tr><td width=25% valign=center align=right><font class="text">ФИО *:&nbsp; &nbsp;</font></td>
                <td width=65% valign=top align=left colspan=2><input class="text" name="user_name" type="text" value="<?php echo $user_name; ?>" size="30" maxlength="50" style="BACKGROUND: #ffffff; HEIGHT: 17px; WIDTH: 275px"></td></tr>
            <tr><td width=25% valign=center align=right><font class="text">Тел/Факс :&nbsp; &nbsp;</font></td>
                <td width=65% valign=top align=left colspan=2><input class="text" name="telephone" type="text" value="<?php echo $telephone; ?>" size="30" maxlength="30" style="BACKGROUND: #ffffff; HEIGHT: 17px; WIDTH: 275px"></td></tr>
            <tr><td width=25% valign=center align=right><font class="text">E-mail *:&nbsp; &nbsp;</font></td>
                <td width=65% valign=top align=left colspan=2><input class="text" name="e_mail" type="text" value="<?php echo $e_mail; ?>" size="30" maxlength="50" style="BACKGROUND: #ffffff; HEIGHT: 17px; WIDTH: 275px"></td></tr>
            <tr><td width=25% valign=center align=right><font class="text">www :&nbsp; &nbsp;</font></td>
                <td width=65% valign=top align=left colspan=2><input class="text" name="www" type="text" value="<?php echo $www; ?>" size="30" maxlength="200" style="BACKGROUND: #ffffff; HEIGHT: 17px; WIDTH: 275px"></td></tr>
            <tr><td width=25% valign=center align=right><font class="text">UIN&nbsp;ICQ :&nbsp; &nbsp;</font></td>
                <td width=65% valign=top align=left colspan=2><input class="text" name="icq" type="text" value="<?php echo $icq; ?>" size="30" maxlength="200" style="BACKGROUND: #ffffff; HEIGHT: 17px; WIDTH: 275px"></td></tr>
            <tr><td width=25% valign=center align=right><font class="text">Выберите логин *:&nbsp; &nbsp;</font></td>
                <td width=65% valign=top align=left colspan=2><input class="text" name="login" type="text" value="<?php echo $login; ?>" size="30" maxlength="200" style="BACKGROUND: #ffffff; HEIGHT: 17px; WIDTH: 275px"></td></tr>
            <tr><td width=25% valign=center align=right><font class="text">Выберите пароль&nbsp;*:&nbsp; &nbsp;</font></td>
                <td width=65% valign=top align=left colspan=2><input class="text" name="password1" type="password" value="<?php echo $password; ?>" size="30" style="BACKGROUND: #ffffff; HEIGHT: 17px; WIDTH: 275px"></td></tr>
            <tr><td width=25% valign=center align=right><font class="text">Повтор&nbsp;пароля&nbsp;*:&nbsp; &nbsp;</font></td>
                <td width=65% valign=top align=left colspan=2><input class="text" name="password2" type="password" value="<?php echo $password; ?>" size="30" maxlength="20" style="BACKGROUND: #ffffff; HEIGHT: 17px; WIDTH: 275px"></td></tr>
            <tr><td width=25% valign=center align=right><font class="text">Комментарии,&nbsp;пожелания&nbsp;:&nbsp;&nbsp;&nbsp;</font></td>
                <td width=65% valign=top align=left colspan=2><textarea class="text" name="info_registration" cols="30" style="BACKGROUND: #ffffff; HEIGHT: 50px; WIDTH: 275px"><?php echo $info_registration; ?></textarea></td></tr>

            <tr><td height=10 colspan=3></td><tr>
            <tr><td valign=center align=center colspan=3><input type = 'image' src = 'img/insert.gif'></td></tr>
            <tr><td height=10 colspan=3></td><tr>
        </table>
    </form>
<?    
echo"<div align='center'><a href='users.php?action=list'>Вернутся к списку ползователей</a></div>";
}

    if($action == 'flag'){
            $idusers = mysqli_real_escape_string($mysqli, $_GET["idusers"]);
$sql = "UPDATE users SET flag = true WHERE  idusers='" . $idusers . "'"; 

if ($conn->query($sql) === TRUE) {
  echo "Record updated successfully";
} else {
  echo "Error updating record: " . $conn->error;
}

$action='list';
}
    if($action == 'list'){

if ($rollNum === '1'||$rollNum === '4') {
    // Использование подготовленного выражения для предотвращения SQL-инъекции
    $sql = "SELECT * FROM users WHERE rollNum = '$rollNum' AND statNum = '$statNum'";
    $link = null;
} elseif ($flag === '0') {
    $sql = "SELECT * FROM users WHERE (rollNum = '$rollNum' OR rollNum = '$rollNum2') AND flag = '0'";
    $link = true;
} else {
    $sql = "SELECT * FROM users WHERE rollNum = '$rollNum' AND statNum = '$statNum' AND flag = '1'";
   $link = null;
}$result = $conn->query($sql);

// Проверка на наличие результатов
if ($result->num_rows > 0) {
    // Метаданные полей нужно получить ДО выборки всех строк — иначе после
    // полного перебора fetch_assoc() на части конфигураций mysqli заголовок
    // таблицы строится некорректно и последняя строка данных может «пропасть».
    $fields = $result->fetch_fields();

    $eligibleColumns = [];
    $dataRows = [];
    $rowCounter = 0;  // Счетчик строк для чередования фона
    $showFlagLink = ($link === true);

    // Перебор всех строк для определения, какие колонки следует отобразить
    while ($row = $result->fetch_assoc()) {
        $rowData = [];
        foreach ($row as $key => $value) {
            // Проверка на исключение колонок idusers, rollNum, statNum
            if (!in_array($key, ['rollNum', 'statNum', 'flag', 'password'])) {
                $validValue = $value !== null && $value !== '' && $value !== '0' && $value !== '0.00';
                // Если значение в колонке удовлетворяет условию, отмечаем колонку как подлежащую выводу
                if ($validValue) {
                    $eligibleColumns[$key] = true;
                }
                $rowData[$key] = $validValue ? htmlspecialchars($value) : '';
            }
        }
        $dataRows[] = $rowData;
    }

    // Создаем таблицу без границ и добавляем заголовок
    echo "<table style='border-collapse: collapse; border: 0;'>";

$columnNamesMap = [
    'fotouser' => 'Фото',
    'firstName' => 'Имя',
    'lastName' => 'Фамилия',
    'middleName' => 'Отчество',
    'city' => 'Город',
    'phone' => 'Телефон',
    'email' => 'E-mail',
    'password' => 'Пароль',
    'namefirm' => 'Организация',
    'innStr' => 'ИНН',
    'ogrnStr' => 'ОГРН',
    'kppStr' => 'КПП',
    'vidt' => 'Вид техники',
    'marka' => 'Марка авто',
    'godv' => 'Год выпуска',
    'maxgruz' => 'макс грузоподъемность',
    'dkuzov' => 'Длинна кузова',
    'shkuzov' => 'Ширина кузова',
    'vidk' => 'Вид кузова',
    'cenahaurs' => 'Цена за час',
    'cenasmena' => 'Цена за смену',
    'cenakm' => 'Цена за км'
];

echo "<tr style='background-color: #FCC485;'>";
foreach ($fields as $field) {
    if (array_key_exists($field->name, $eligibleColumns)) {
        $displayName = array_key_exists($field->name, $columnNamesMap) ? $columnNamesMap[$field->name] : $field->name;
        echo "<th style='border: 1px solid black;'>" . $displayName . "</th>";
    }
}
        echo "<th style='border: 1px solid black;'></th>";
        echo "<th style='border: 1px solid black;'></th>";
        echo "<th style='border: 1px solid black;'></th>";
        if ($showFlagLink) {
            echo "<th style='border: 1px solid black;'></th>";
        }
echo "</tr>";

foreach ($dataRows as $rowCounter => $row) {
    // Определение цвета строки.
    $rowColor = ($rowCounter % 2 == 0) ? "#f0f5f7" : "#FFE1BF";
    echo "<tr style='background-color: $rowColor;'>";

    // Отрисовка выбранных столбцов.
    foreach ($row as $key => $value) {
        // Проверка, является ли столбец допустимым.
        if (array_key_exists($key, $eligibleColumns)) {
            if ($key === 'fotouser' && !empty($value)) {
                // Преобразование BLOB в base64 и отрисовка как изображение.
                $blobBase64 = base64_encode($value);
                echo "<td style='border: 1px solid black;'><img src='data:image/jpeg;base64,$blobBase64' width='150' /></td>";
                
            } elseif (!empty($value)) {
                echo "<td style='border: 1px solid black;'>$value</td>";
            } else {
                // Если столбец допустим, но значение пустое.
                echo "<td style='border: 1px solid black;'></td>";
            }
        }
    }

    // Добавление колонок с иконками.
    $deleteIcon = "<a href='#'>Удалить</a>"; // Укажите здесь свой URL или обработчик.
    $editIcon = "<a href='#'>Редактировать</a>"; // Укажите здесь свой URL или обработчик.
    $obIcon = "<a href='outputob.php?iduser={$row['idusers']}'>Объявления</a>"; // Укажите здесь свой URL или обработчик.

    echo "<td style='border: 1px solid black;'>$editIcon</td>";
    echo "<td style='border: 1px solid black;'>$deleteIcon</td>";
    echo "<td style='border: 1px solid black;'>$obIcon</td>";

    if ($showFlagLink) {
        $flagLinkHtml = "<a href='?action=flag&rollNum=2&rollNum2=3&statNum=1&flag=0&idusers=" . htmlspecialchars($row['idusers'] ?? '', ENT_QUOTES, 'UTF-8') . "'>Разрешить работу</a>";
        echo "<td style='border: 1px solid black;'>$flagLinkHtml</td>";
    }

    echo "</tr>";
}
    
    echo "</table>";
    
    
$sql = "SELECT fotouser FROM users";
$result = $conn->query($sql);
if ($result->num_rows > 0) {
  // Вывод данных каждой строки
  while($row = $result->fetch_assoc()) {
       $base64Image = base64_encode($row['fotouser'] );
    echo '<img src="data:image/jpeg;base64,'.$base64Image.'" />';
  }
} else {
  echo "0 results";
}
    
} else {
    echo "Записей с указанными параметрами не найдено."; // Уведомление, если данных нет
}
      }
?>
