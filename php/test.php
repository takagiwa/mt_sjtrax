<?php

require_once('mon.php');




$view = false;



// テストパターン ------------------------------------------------------------

$file_list = glob('./data1/*');
if (!is_array($file_list) || (count($file_list) == 0)) {
  echo "[ERROR] Failed to get file list.\n";
  return;
}
foreach ($file_list as $f) {
  if (stristr($f, ".trx") !== false) {
    // is .trx
    // ３行目にスペース区切りで
    echo ">> ".$f."\n";

    $notes = array();
    $turn = 0;

    $fp = fopen($f, "r");
    if ($fp == false) {
      echo "[ERROR] Failed to open file [".$f."]\n";
      continue;
    }
    if ($view) printf("   ----\n");
    $i = 0;
    while (($str = fgets($fp)) !== false) {
      $i++;
      if ($i != 3) continue;
      $str_array = explode(' ', $str);
      if (!is_array($str_array) || (count($str_array) == 0)) {
        echo "[ERROR] Something wrong.\n";
      }
      foreach ($str_array as $n) {
        $str_a = str_split($n);
        $x = '';
        $y = '';
        $t = '';
        foreach ($str_a as $l) {
          if (($l == '+') || ($l == '/') || ($l == '\\')) {
            $t .= $l;
          } else if (is_numeric($l)) {
            $y .= $l;
          } else if (($l == '@') || is_string($l)) {
            $x .= $l;
          }
        }
        if ($view) echo "   ".$x."(".conv2num($x).") | ".$y." | ".$t."\n";

        $notes[$turn] = array($x, $y, $t);

        $turn++;
      }
    }
    if ($view) printf("   ----\n");
    fclose($fp);

    $r = mon($notes);
    if ($r == false) {
    	return;
    }

  } else {
    // not .trx
    // １行に１手
    echo "<< ".$f."\n";

    $notes = array();
    $turn = 0;

    $fp = fopen($f, "r");
    if ($fp == false) {
      echo "[ERROR] Failed to open file [".$f."]\n";
      continue;
    }
    if ($view) printf("   ----\n");
    while (($str = fgets($fp)) !== false) {
      $str = trim($str);
      if (mb_strlen($str) < 3) {
        break;
      }
      if (0) echo $str;

      $str_a = str_split($str);
      $x = '';
      $y = '';
      $t = '';
      foreach ($str_a as $l) {
        if (($l == '+') || ($l == '/') || ($l == '\\')) {
          $t .= $l;
        } else if (is_numeric($l)) {
          $y .= $l;
        } else if (($l == '@') || is_string($l)) {
          $x .= $l;
        }
      }
      if ($view) echo "   ".$x."(".conv2num($x).") | ".$y." | ".$t."\n";

      $notes[$turn] = array($x, $y, $t);

      $turn++;
    }
    if ($view) printf("   ----\n");
    fclose($fp);

    $r = mon($notes);
    if ($r == false) {
    	return;
    }
  }

}


return;


// 棋譜 ----------------------------------------------------------------------

$file_list = glob('./data2/*');
if (!is_array($file_list) || (count($file_list) == 0)) {
  echo "[ERROR] Failed to get file list.\n";
  return;
}
foreach ($file_list as $f) {
  echo ">> ".$f."\n";

  $notes = array();
  $turn = 0;

  $fp = fopen($f, "r");
  if ($fp == false) {
    echo "[ERROR] Failed to open file [".$f."]\n";
    continue;
  }
  if ($view) printf("   ----\n");
  $i = 0;
  while (($str = fgets($fp)) !== false) {
    // ヘッダを無視
    $i++;
    if ($i < 3) continue;

    $str = trim($str);
    if (mb_strlen($str) < 3) {
      break;
    }

    $str_a = str_split($str);
    $x = '';
    $y = '';
    $t = '';
    foreach ($str_a as $l) {
      if (($l == '+') || ($l == '/') || ($l == '\\')) {
        $t .= $l;
      } else if (is_numeric($l)) {
        $y .= $l;
      } else if (($l == '@') || is_string($l)) {
        $x .= $l;
      }
    }
    if ($view) echo "   ".$x."(".conv2num($x).") | ".$y." | ".$t."\n";

    $notes[$turn] = array($x, $y, $t);

    $turn++;
  }
  if ($view) printf("   ----\n");
  fclose($fp);

  mon($notes);

}
