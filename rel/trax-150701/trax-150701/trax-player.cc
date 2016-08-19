/*
  Trax Design Competition test player

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

#include <stdlib.h> // random()

#include "trax.h"

std::string player1, player2;

std::string player_name(int p){
  std::string who = (p==1) ? player1 : player2;
  return "["+who+"]";
}


std::string player(int p){
  switch(p){
  case 1:
    return "white";
  case 2:
    return "red";
  }
  return "someone unknown";
}
// ----------------------------------------------------------------------

class trax_player : public trax {
public:
  trax_player(){ silent=true; };
  int try_random();
  int try_scan();

protected:
  void save();
  void recall();

  int left_b, right_b, top_b, bottom_b;

  std::map <xy, char> board_b;
  std::map <xy, char> board_color_b;
  std::map <xy, char> board_marks_b;
  // char board_b[BOARD_MAX][BOARD_MAX];
  // char board_color_b[BOARD_MAX][BOARD_MAX];
  // char board_marks_b[BOARD_MAX][BOARD_MAX];
};

void trax_player::recall(){
  left   = left_b;
  right  = right_b;
  top    = top_b;
  bottom = bottom_b;

  board = board_b;
  board_color = board_color_b;
  board_marks = board_marks_b;
}

void trax_player::save(){
  left_b   = left;
  right_b  = right;
  top_b    = top;
  bottom_b = bottom;

  board_b = board;
  board_color_b = board_color;
  board_marks_b = board_marks;
}


// random trial
int trax_player::try_random(){
  // std::cout << "L: " << left
  //           << " R: " << right
  //           << " T: " << top
  //           << " B: " << bottom << "\n";

  int board_width  = right-left;  // possible place: 0 - board_width+1
  int board_height = bottom-top;  // possible place: 0 - board_height+1;

  char t;
  switch(random()%3){
  case 0:  t='+'; break;
  case 1:  t='/'; break;
  default: t='\\'; break;
  }

  int width = board_width+1;
  int height = board_height+1;

  while(1){
    move mo("@0+");
    mo.x = random()%(width+1);
    mo.y = random()%(height+1);
    mo.tile=t;

      save();
      if(place(mo, 100)){
        // up to "ZZ" column
        char a;
        if(mo.x>26){
          a = (mo.x-27)/26;
          a+= 'A';
          std::cout << a;
          mo.x = (mo.x-1)%26+1;
        }
        a = mo.x;
        a += '@';
        std::cout << a;

        std::cout << mo.y << t << "\n";

        return 0;
      } else {
        recall();
      }
  }

  return -1;
}

// X-Y scan
int trax_player::try_scan(){
  // std::cout << "L: " << left
  //           << " R: " << right
  //           << " T: " << top
  //           << " B: " << bottom << "\n";

  int board_width  = right-left;  // possible place: 0 - board_width+1
  int board_height = bottom-top;  // possible place: 0 - board_height+1;

  char t;
  switch(random()%3){
  case 0:  t='+'; break;
  case 1:  t='/'; break;
  default: t='\\'; break;
  }

  for(int x=0; x<=board_width+1; x++){
    for(int y=0; y<=board_height+1; y++){
      move mo("@0+");
      mo.x = x;
      mo.y = y;
      mo.tile=t;

      save();
      if(place(mo, 100)){
        // up to "ZZ" column
        char a;
        if(x>26){
          a = (x-27)/26;
          a+= 'A';
          std::cout << a;
          x = (x-1)%26+1;
        }
        a = x;
        a += '@';
        std::cout << a;

        std::cout << y << t << "\n";

        return 0;
      } else {
        recall();
      }
    }
  }

  return 0;
}


// ----------------------------------------------------------------------

int main(){
  trax_player t;
  int turn = 1;

  t.clear_board();
  srandom(time(0));

  // initialization
  std::string m;
  bool first_player = false;

  while (std::cin >> m){
    if (m=="-T") std::cout << "0X\n";
    if (m=="-B"){ first_player=false; break; };
    if (m=="-W"){ first_player=true;  break; };
  }

  if (first_player) {
    m = "@0";
    m += (random()%2==0) ? "+" : "/";
    std::cout << m << "\n";

    move mo = move(m);
    t.place(mo, turn);
    turn++;
  }

  while ( std::cin >> m ){
    /* 相手 */
    move mo = move(m);
    if (!t.place(mo, turn)){
      std::cerr << "opponent violation\n";
      return -1;
    }
    turn++;

    /* 自分 */
    t.try_random();
    turn ++;
  }

  return 0;
}
