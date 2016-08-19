#include <iostream>
#include "trax.h"

std::ostream& operator<<(std::ostream& stream, const move& m){
  stream << "X:" << m.x << ", Y:" << m.y << ", Tile:" << m.tile;
  return stream;
}

move::move(const std::string m){
  int step=0;
  int pos=0;

  x=0;
  y=0;
  
  while(pos < m.length()){
    char mm = m[pos];
    switch(step){
    case 0:
      if(mm=='@'){ x=0; break; }
      if('A'<=mm && mm<='Z'){ x*=26; x+= mm-'A'+1; break; }
      y = mm-'0';
      step = 1;
      break;
    case 1:
      if('0'<=mm && mm<='9'){ y*=10; y+= mm-'0'; break; }
      tile = mm;
      step = 2;
      break;
    case 2:
      break;
    }
    pos++;
  }
}
