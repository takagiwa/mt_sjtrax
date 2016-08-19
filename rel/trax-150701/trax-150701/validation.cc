#include <iostream>
#include "trax.h"

bool trax::is_prohibited_3(const int x, const int y){
  int lc, rc, uc, dc;

  get_around_colors(x, y, lc, rc, uc, dc);
  if ( ( lc==rc && rc==uc && uc!=0 ) ||
       ( rc==uc && uc==dc && dc!=0 ) ||
       ( uc==dc && dc==lc && lc!=0 ) ||
       ( dc==lc && lc==rc && rc!=0 ) ) {

    std::cout << "**** 3 LINES WITH SAME COLOR! ****\n";
    return true;
  }
  return false;
}

// pre-place check (not sufficient for post-place check)
bool trax::is_consistent_placement(int x, int y, char tile){
  int lc, rc, uc, dc;


  get_around_colors(x, y, lc, rc, uc, dc);
  if (tile=='+'){
    if (lc!=rc && (lc!=0 && rc!=0)){
      if(!silent)
	      std::cout << "**** DIFFERENT COLOR ON LEFT & RIGHT ON '+' ****\n";
      return false;
    }

    if (uc!=dc && (uc!=0 && dc!=0)){
      if(!silent)
	      std::cout << "**** DIFFERENT COLOR ON UPPER & LOWER ON '+' ****\n";
      return false;
    }
  }

  if (tile=='/'){
    if (lc!=uc && (lc!=0 && uc!=0)){
      if(!silent)
	      std::cout << "**** DIFFERENT COLOR ON LEFT & UPPER ON '/' ****\n";
      return false;
    }

    if (dc!=rc && (dc!=0 && rc!=0)){
      if(!silent)
	      std::cout << "**** DIFFERENT COLOR ON LOWER & RIGHT ON '/' ****\n";
      return false;
    }
  }

  if (tile=='\\'){
    if (lc!=dc && (lc!=0 && dc!=0)){
      if(!silent)
	      std::cout << "**** DIFFERENT COLOR ON LEFT & LOWER ON '\\' ****\n";
      return false;
    }

    if (uc!=rc && (uc!=0 && rc!=0)){
      if(!silent)
	      std::cout << "**** DIFFERENT COLOR ON UPPER & RIGHT ON '\\' ****\n";
      return false;
    }
  }

  return true;
}

// post-place test
bool trax::is_line_color_connected(int x, int y){
  // compare with my color
  int lc, rc, uc, dc;
  char tile = lookup(board, x, y);

  get_around_colors(x, y, lc, rc, uc, dc);

  int my_l, my_r, my_u, my_d;
  my_r = lookup(board_color, x, y);
  my_l = (tile=='+')  ? my_r : opposite_color(my_r);
  my_u = (tile=='\\') ? my_r : opposite_color(my_r);
  my_d = (tile=='/')  ? my_r : opposite_color(my_r);

  if(my_r!=rc && (rc!=0)){
    if(!silent)
      std::cout << "**** DIFFERENT COLOR ON RIGHT EDGE ****\n";
    return false;
  }

  if(my_l!=lc && (lc!=0)){
    if(!silent)
      std::cout << "**** DIFFERENT COLOR ON LEFT EDGE ****\n";
    return false;
  }

  if(my_u!=uc && (uc!=0)){
    if(!silent)
      std::cout << "**** DIFFERENT COLOR ON TOP EDGE ****\n";
    return false;
  }

  if(my_d!=dc && (dc!=0)){
    if(!silent)
      std::cout << "**** DIFFERENT COLOR ON BOTTOM EDGE ****\n";
    return false;
  }
  return true;
}

bool trax::is_board_consistent(){
  for (int y=top; y<bottom; y++){
    for (int x=left; x<right; x++){
      if (lookup(board, x, y)!=0){
	      if (!is_consistent_placement(x, y, lookup(board, x, y)))
          return false;
	      if (!is_line_color_connected(x, y))
          return false;
      }

      if (lookup(board, x, y)==0)
	      if (is_prohibited_3(x,y))
          return false;
    }
  }
  return true;
}
