/*
  Trax Design Competition test (and host) program

  Platform:
  - Developed and tested on FreeBSD 9.3 (amd64)
  - Will work on other platforms with C++ compiler.

  Usage:
  See http://lut.eee.u-ryukyu.ac.jp/traxjp/ (written in Japanese)

  License:
  - Yasunori Osana <osana@eee.u-ryukyu.ac.jp> wrote this file.
  - This file is provided "AS IS" in the beerware license rev 42.
  (see http://people.freebsd.org/~phk/)

*/

#include <iostream>
#include <iomanip>

#include "trax.h"

const std::string esc_ul = "\033[4m";
const std::string esc_rev = "\033[7m";
const std::string esc_red = "\033[31m";
const std::string esc_normal = "\033[0m";

// const std::string esc_ul = "_";
// const std::string esc_rev = "=";
// const std::string esc_red = "*";
// const std::string esc_normal = "";


char lookup(const std::map<xy,char>& b, int x, int y){
  std::map<xy, char>::const_iterator ite;
  ite = b.find(xy(x,y));
  if(ite==b.end()) return 0;
  return ite->second;
}

void trax::clear_marks(){
  board_marks.clear();
}

void trax::clear_board(){

  board.clear();
  board_color.clear();
  board_marks.clear();

  left = right = top = bottom = 0;

  red_loop = white_loop = false;
  red_line = white_line = false;
}

std::ostream& operator<<(std::ostream& stream, const trax& t){
  if (t.right-t.left > 26){
    // second column such as "AA"
    stream << "   |";
    for(int x=t.left; x<=t.right; x++){
      if (x<=t.left+26) stream << "  ";
      else stream << (char)((x-t.left-1)/26+'@') << ' ';
    }

    stream << "|\n";
  }

  stream << "   |";
  for(int x=t.left; x<=t.right; x++){
    if (x==t.left) stream << "@ ";
    else stream << (char)((x-t.left-1)%26+'A') << ' ';
  }
  stream << "|\n";

  for(int y=t.top; y<=t.bottom; y++){
    stream << std::setw(3) << y-t.top;
    for(int x=t.left; x<=t.right; x++){
      char tile = lookup(t.board, x, y);
      if (tile==0) tile = ' ';
      stream << (x==t.left ? "|" : "")
             << (lookup(t.board_marks, x, y) == 1 ? esc_rev : "")
             << (lookup(t.board_marks, x, y) == 2 ? esc_ul  : "")
             << (lookup(t.board_color, x, y) == 1 ? esc_red : "")
             << tile << esc_normal << ' '
             << (x==t.right ? "|" : "");
    }
    stream << std::endl;
  }
  return stream;
}


int trax::opposite_color(const int c){
  if (c==0) return 0;
  if (c==1) return 2;
  return 1;
}

void trax::get_around_colors(const int x, const int y,
                             int& lc, int& rc, int& uc, int& dc){

  // (x-1, y), (x+1, y), (x, y-1), (x, y+1) の４個をとる。
  // あとは opposite_color 処理

  // left color
  lc = lookup(board_color, x-1, y);

  // right color
  rc = lookup(board, x+1, y)=='+' ? lookup(board_color, x+1, y) :
    opposite_color(lookup(board_color, x+1, y));

  // up color
  uc = lookup(board, x, y-1)=='+' ? opposite_color(lookup(board_color, x, y-1)):
    lookup(board, x, y-1)=='/' ? lookup(board_color, x, y-1) :
    opposite_color(lookup(board_color, x, y-1));

  // down color
  dc = lookup(board, x, y+1)=='+' ? opposite_color(lookup(board_color, x, y+1)):
    lookup(board, x, y+1)=='\\' ? lookup(board_color, x, y+1) :
    opposite_color(lookup(board_color, x, y+1));
}


bool trax::place(move mo, int turn){
  int x = left +mo.x;
  int y = top  +mo.y;

  /* 初手のチェック */
  if (turn==1){
    if ( ! ( (mo.x == 0 && mo.y == 0) &&
             (mo.tile == '+' || mo.tile == '/') ) ){
      if(!silent) std::cout << "\n**** ILLEGAL FIRST MOVE! ****\n";
      return false;
    }
  }

  /* マイナスの領域に置いたから、盤面をマイナス方向に広げている */
  if (mo.x == 0){ left--; }
  if (mo.y == 0){ top--;   }

  /* 既に置かれている場所でないか */
  if (lookup(board, x, y) != 0){
    if(!silent) std::cout << "**** ALREADY OCCUPIED! ****\n";
    return false;
  }

  board_marks[xy(x,y)] = 1;

  /* プラス方向に広げる */
  if (right < x) right = x;
  bottom = (bottom < y) ? y : bottom;

  return place(x, y, mo.tile, turn);
}

bool trax::place(const int x, const int y, const char tile, int turn){
  int color = 0;

  board[xy(x,y)] = tile;

  // check left, right, up, down
  int lc, rc, uc, dc;
  get_around_colors(x, y, lc, rc, uc, dc);

  // 孤立していないかチェック
  // Isolated
  if ( lc==rc && rc==uc && uc==dc && dc == 0 ){
    if (turn != 1) {
      if(!silent) std::cout << "\n**** ISOLATED ****\n";
      color = 1;
      return false; // This should happen only at 1st move only.
    }
    color = 1;
  }


  // Tiles around
  if(!silent){
    std::cout << (lc!=0 ? ((lc==1 ? esc_red : "") + "L" + esc_normal) : "")
              << (rc!=0 ? ((rc==1 ? esc_red : "") + "R" + esc_normal) : "")
              << (uc!=0 ? ((uc==1 ? esc_red : "") + "U" + esc_normal) : "")
              << (dc!=0 ? ((dc==1 ? esc_red : "") + "D" + esc_normal) : "")
              << "\n";
  }

  // 3 same color check
  if(is_prohibited_3(x, y)) return false; // if true, it's prohibited pattern

  // tile requirement check
  if(!is_consistent_placement(x, y, tile)) return false;

  // color the tile
  if (color==0){ // if not already colored
    if (tile=='+')  color = (lc==1 || rc==1 || uc==2 || dc==2) ? 1 : 2;
    if (tile=='/')  color = (lc==1 || uc==1 || dc==2 || rc==2) ? 2 : 1;
    if (tile=='\\') color = (lc==1 || dc==1 || uc==2 || rc==2) ? 2 : 1;
  }

  if(!silent){
    if (color==0) std::cout << "**** SOMETHING IS WRONG ****\n";}

  board_color[xy(x,y)]=color;

  scan_forced();
  trace_loop(x, y);
  trace_line();

  return true;
}

bool trax::scan_forced(){
  for(int y=top; y<=bottom; y++){
    for(int x=left; x<=right; x++){
      if(lookup(board_color, x, y) != 0) continue;

      int lc, rc, uc, dc;
      get_around_colors(x, y, lc, rc, uc, dc);

      char forced = ' ';
      if ( (lc==uc && uc!=0 ) || (dc==rc && rc!=0 ) ) forced = '/';
      if ( (rc==uc && uc!=0 ) || (dc==lc && lc!=0 ) ) forced = '\\';
      if ( (lc==rc && rc!=0 && rc!=dc && rc!=uc) ||
	         (uc==dc && dc!=0 && dc!=lc && dc!=lc) ) forced = '+';

      if(forced != ' '){
        if(!silent){
          std::cout << "Forced play: [X:" << x-left << ", Y:" << y-top
                    << ", Tile:" << forced << "] "; }
	      place(x, y, forced, -1);
	      return true;
      }
    }
  }
  // No more forced play here
  return false;
}
