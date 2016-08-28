<?php

//----------------------------------------------------------------------------

function conv2num($str = '') {
  if (mb_strlen($str) == 0) {
    return -1;
  }

  $a = str_split($str);
  if (!is_array($a) || (count($a) == 0)) {
    return -1;
  }

  $c = 1;
  $r = 0;
  foreach ($a as $l) {
    if ($l == '@') {
      return 0;
    }
    $r *= 26;
    $r += ord($l) - 0x41 + 1; // A は 0 ではなく 1 だから
  }
  return $r;
}

//----------------------------------------------------------------------------

function lookup($board, $x, $y)
{
  if (!is_array($board)) {
    return -1; // error
  }
  if (!is_numeric($x) || !is_numeric($y)) {
    return -2; // error
  }
  if (count($board) == 0) {
    return 0; // empty
  }

  foreach ($board as $k => $v) {
    if (($v[0] == $x) && ($v[1] == $y)) {
      return $v[2];
    }
  }

  return 0; // not found
}

function opposite_color($c) {
  if ($c == 0) return 0;
  if ($c == 1) return 2;
  return 1;
}

function get_around_colors($x, $y, $board, $board_color)
{
  if (!is_numeric($x) || !is_numeric($y)) {
    return -1; // error
  }

  $ret = array('lc' => 0, 'rc' => 0, 'uc' => 0, 'dc' => 0);

  $ret['lc'] = lookup($board_color, $x-1, $y);

  $b = lookup($board, $x+1, $y);
  $c = lookup($board_color, $x+1, $y);
  if ($b == '+') {
    $ret['rc'] = $c;
  } else {
    $ret['rc'] = opposite_color($c);
  }

  $b = lookup($board, $x, $y-1);
  $c = lookup($board_color, $x, $y-1);
  if ($b == '+') {
    $ret['uc'] = opposite_color($c);
  } else {
    if ($b == '/') {
      $ret['uc'] = $c;
    } else {
      $ret['uc'] = opposite_color($c);
    }
  }

  $b = lookup($board, $x, $y+1);
  $c = lookup($board_color, $x, $y+1);
  if ($b == '+') {
    $ret['dc'] = opposite_color($c);
  } else {
    if ($b == '\\') {
      $ret['dc'] = $c;
    } else {
      $ret['dc'] = opposite_color($c);
    }
  }

  return $ret;
}

function is_prohibited_3($x, $y, $board, $board_color)
{
  $ret = get_around_colors($x, $y, $board, $board_color);
  if (   ( ($ret['lc'] == $ret['rc']) && ($ret['rc'] == $ret['uc']) && ($ret['uc'] != 0))
      || ( ($ret['rc'] == $ret['uc']) && ($ret['uc'] == $ret['dc']) && ($ret['dc'] != 0))
      || ( ($ret['uc'] == $ret['dc']) && ($ret['dc'] == $ret['lc']) && ($ret['lc'] != 0))
      || ( ($ret['dc'] == $ret['lc']) && ($ret['lc'] == $ret['rc']) && ($ret['rc'] != 0)) ) {
    return true;
  }

  return false;
}

function is_consistent_placement($x, $y, $tile, $board, $board_color)
{
  $ret = get_around_colors($x, $y, $board, $board_color);

  if ($tile == '+') {
    if (($ret['lc'] != $ret['rc']) && (($ret['lc'] != 0) && ($ret['rc'] != 0))) {
      return true;
    }
    if (($ret['uc'] != $ret['dc']) && (($ret['uc'] != 0) && ($ret['dc'] != 0))) {
      return true;
    }
  }

  if ($tile == '/') {
    if (($ret['lc'] != $ret['uc']) && (($ret['lc'] != 0) && ($ret['uc'] != 0))) {
      return true;
    }
    if (($ret['dc'] != $ret['rc']) && (($ret['dc'] != 0) && ($ret['rc'] != 0))) {
      return true;
    }
  }

  if ($tile == '\\') {
    if (($ret['lc'] != $ret['dc']) && (($ret['lc'] != 0) && ($ret['dc'] != 0))) {
      return true;
    }
    if (($ret['uc'] != $ret['rc']) && (($ret['uc'] != 0) && ($ret['rc'] != 0))) {
      return true;
    }
  }

  return false;
}


function place($mo_x, $mo_y, $tile, $turn, &$top, &$bottom, &$left, &$right, &$board, &$board_color, &$board_marks)
{	
	$x = $left + $mo_x;
	$y = $top + $mo_y;

	if ($turn > 0) {

		// マップのサイズを更新
		if ($mo_x == 0) {
			$left -= 1;
		}
		if ($mo_y == 0) {
			$top -= 1;
		}
		if ($right < $x) {
			$right = $x;
		}
		if ($bottom < $y) {
			$bottom = $y;
		}

		$res = lookup($board, $x, $y);
		if ($res < 0) {
			echo "**** INVALID PARAMETER at turn ".$turn." ****\n";
			return false;
		}
		if ($res > 0) {
			echo "*** ALREADY OCCUPIED! ****\n";
			return false;
		}

		$board_marks[] = array($x, $y, 1);

	}

	$color = 0;
	
	$board[] = array($x, $y, $tile);

	// check left, right, up, down
	$ret = get_around_colors($x, $y, $board, $board_color);
	
	// Isolated
	if (($ret['lc'] == $ret['rc']) && ($ret['rc'] == $ret['uc']) && ($ret['uc'] == $ret['dc']) && ($ret['dc'] == 0)) {
		if ($turn != 1) {
			echo "**** ISOLATED at turn ".$turn." ****\n";
			if (0) {
				var_dump($ret);
				var_dump($board);
				var_dump($board_color);
			}
			return false;
		}
		$color = 1;
	}
	
	// Tiles around
	
	// 3 same color check
	$ret2 = is_prohibited_3($x, $y, $board, $board_color);
	if ($ret2) {
		echo "**** 3 LINES WITH SAME COLOR! at turn ".$turn." ****\n";
		return false;
	}
	
	// tile requirement check
	$ret2 = is_consistent_placement($x, $y, $tile, $board, $board_color);
	if ($ret2) {
		echo "**** IS NOT CONSISTEND PLACEMENT at turn ".$turn." **** \n";
		return false;
	}
	
	// color the tile
	if ($color == 0) {
		if ($tile == '+') {
			if (($ret['lc'] == 1) || ($ret['rc'] == 1) || ($ret['uc'] == 2) || ($ret['dc'] == 2)) {
				$color = 1;
			} else {
				$color = 2;
			}
		}
		if ($tile == '/') {
			if (($ret['lc'] == 1) || ($ret['uc'] == 1) || ($ret['dc'] == 2) || ($ret['rc'] == 2)) {
				$color = 2;
			} else {
				$color = 1;
			}
		}
		if ($tile == '\\') {
			if (($ret['lc'] == 1) || ($ret['dc'] == 1) || ($ret['uc'] == 2) || ($ret['rc'] == 2)) {
				$color = 2;
			} else {
				$color = 1;
			}
		}
	}
	if ($color == 0) {
		echo "**** SOMETHING WRONG ****\n";
		return false;
	}
	
	$board_color[] = array($x, $y, $color);

	return true;
}



//----------------------------------------------------------------------------

/*

タイル
+ であればクロス
/ であれば、左と上、右と下がつながる
\ であれば、左と下、右と上がつながる

$notes のキーは 0 オリジン

最初であれば、ノーチェック。
白が先攻
最初は + か / のみ。上に 白 が来るように

最初のが + なら、上下に白、左右に赤。
→ 次の白は、






*/









function mon($notes = array()) {
  if (!is_array($notes) || (count($notes) == 0)) return false;

  if (0) {
    $a = current($notes);
    $k = key($notes);
    echo "      ".$k." : ".conv2num($a[0])." / ".$a[1]." / ".$a[2]."\n";
    return true;
  }
  if (0) {
  	foreach ($notes as $n) {
  		echo $n[0].$n[1].$n[2]." >> ".conv2num($n[0])."/".$n[1]."/".$n[2]."\n";
  	}
  }

  // t.clear_board()
  //  board.clear() = std::map<xy, char>
  //  board_color.clear() = std::map<xy, char>
  //  board_marks.clear() = std::map<xy, char>
  //  left = right = top = bottom = 0;
  //  red_loop = white_loop = false;
  //  red_line = white_line = false;

  $board = array();
  $board_color = array();
  $board_marks = array();

  $left = 0;
  $right = 0;
  $top = 0;
  $bottom = 0;

  $red_loop = false;
  $white_loop = false;
  $red_line = false;
  $white_line = false;

  foreach ($notes as $k => $note) {
    $mo = array('x' => conv2num($note[0]), 'y' => $note[1], 'tile' => $note[2]);
    $turn = $k + 1;

    //------------------------------------------------------------------------
    // trax::place(move mo, int turn)
    $x = $left + $mo['x'];
    $y = $top  + $mo['y'];
    
    echo " --> initial ".$x.", ".$y.", ".$top.", ".$bottom.", ".$left.", ".$right."\n";

    if ($turn == 1) {
      if (!(($mo['x'] == 0 && $mo['y'] == 0) && ($mo['tile'] == '+' || $mo['tile'] == '/'))) {
        echo "**** ILLEGAL FIRST MOVE! ****\n";
        return false;
      }
    }

    if (0) {

    if ($mo['x'] == 0) { $left -= 1; }
    if ($mo['y'] == 0) { $top -= 1; }

    $res = lookup($board, $x, $y);
    if ($res < 0) {
      echo "**** INVALID PARAMETER at turn ".$turn." ****\n";
      return;
    }
    if ($res > 0) {
      echo "*** ALREADY OCCUPIED! ****\n";
      return;
    }

    $board_marks[] = array($x, $y, 1);

    if ($right < $x) { $right = $x; }
    if ($bottom < $y) { $bottom = $y; }

    //------------------------------------------------------------------------
    // trax::place(const int x, const int y, const char tile, int turn)
    $tile = $mo['tile'];
    $color = 0;

    $board[] = array($x, $y, $tile);

    // check left, right, up, down
    $ret = get_around_colors($x, $y, $board, $board_color);

    // Isolated
    if (($ret['lc'] == $ret['rc']) && ($ret['rc'] == $ret['uc']) && ($ret['uc'] == $ret['dc']) && ($ret['dc'] == 0)) {
      if ($turn != 1) {
        echo "**** ISOLATED at turn ".$turn." ****\n";
        if (0) {
        var_dump($ret);
        var_dump($board);
        var_dump($board_color);
        }
        return;
      }
      $color = 1;
    }

    // Tiles around

    // 3 same color check
    $ret = is_prohibited_3($x, $y, $board, $board_color);
    if ($ret) {
      echo "**** 3 LINES WITH SAME COLOR! at turn ".$turn." ****\n";
      return;
    }

    // tile requirement check
    $ret = is_consistent_placement($x, $y, $tile, $board, $board_color);
    if ($ret) {
      echo "**** IS NOT CONSISTEND PLACEMENT at turn ".$turn." **** \n";
      return;
    }

    // color the tile
    if ($color == 0) {
      if ($tile == '+') {
        if (($ret['lc'] == 1) || ($ret['rc'] == 1) || ($ret['uc'] == 2) || ($ret['dc'] == 2)) {
          $color = 1;
        } else {
          $color = 2;
        }
      }
      if ($tile == '/') {
        if (($ret['lc'] == 1) || ($ret['uc'] == 1) || ($ret['dc'] == 2) || ($ret['rc'] == 2)) {
          $color = 2;
        } else {
          $color = 1;
        }
      }
      if ($tile == '\\') {
        if (($ret['lc'] == 1) || ($ret['dc'] == 1) || ($ret['uc'] == 2) || ($ret['rc'] == 2)) {
          $color = 2;
        } else {
          $color = 1;
        }
      }
    }

    $board_color[] = array($x, $y, $color);

    }
    
    
    $r = place($mo['x'], $mo['y'], $mo['tile'], $turn, $top, $bottom, $left, $right, $board, $board_color, $board_marks);
    if ($r == false) {
    	echo "*** Failed to place ***\n";
    	return;
    }

    if (0) var_dump($board_color);

	// trax::scan_forced()
//	for ($ey = $top; $ey <= $bottom; $ey++) {
//		for ($ex = $left; $ex <= $right; $ex++) {
			for ($fy = $top; $fy <= $bottom; $fy++) {
				for ($fx = $left; $fx <= $right; $fx++) {
					$r = lookup($board_color, $fx, $fy);
					if ($r != 0) {
						continue;
					}

					$r = get_around_colors($fx, $fy, $board, $board_color);
					$forced = ' ';
					if ((($r['lc'] == $r['uc']) && ($r['uc'] != 0)) || (($r['dc'] == $r['rc']) && ($r['rc'] != 0))) {
						$forced = '/';
					}
					if ((($r['rc'] == $r['uc']) && ($r['uc'] != 0)) || (($r['dc'] == $r['lc']) && ($r['lc'] != 0))) {
						$forced = '\\';
					}
					if ((($r['lc'] == $r['rc']) && ($r['rc'] != 0) && ($r['rc'] != $r['dc']) && ($r['rc'] != $r['uc']))
						|| (($r['uc'] == $r['dc']) && ($r['dc'] != 0) && ($r['dc'] != $r['lc']) && ($r['dc'] != $r['lc']))) {
						$forced = '+';
					}

					if (0) echo "x: ".$fx." / y: ".$fy." / u: ".$r['uc']." / d: ".$r['dc']." / l: ".$r['lc']." / r: ".$r['rc']." / t: ".$forced."\n";
					if ($forced == ' ') {
						continue;
					}

					if (0) echo "Forced: ".$forced."\n";
					if (1) echo "x: ".$fx." / y: ".$fy." / u: ".$r['uc']." / d: ".$r['dc']." / l: ".$r['lc']." / r: ".$r['rc']." / t: ".$forced."\n";
						
					$r = place($fx, $fy, $forced, -1, $top, $bottom, $left, $right, $board, $board_color, $board_marks);
					if ($r == false) {
						return false;
					}
					goto forced_end;
				}
			}
//		}
//	}
forced_end:







    echo "  --> ended ".$top.", ".$bottom.", ".$left.", ".$right."\n";

  }

















}
