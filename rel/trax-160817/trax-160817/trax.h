#include <map>
#include <ostream>

#ifndef _TRAX_H_
#define _TRAX_H_

typedef std::pair<int,int> xy;

class move {
public:
  int x, y;
  char tile;
  move(const std::string);
};


char lookup(const std::map<xy,char>& b, int x, int y);

class trax {
public:
  // static const int BOARD_MAX = 100;

  trax(){ silent=false; }
  
  void clear_marks();
  void clear_board();

  bool is_board_consistent();
  bool place(move, int);
  bool place(const int, const int, const char, int);

  bool trace_loop();
  bool trace_line();

  bool loop() const  { return (red_loop || white_loop); }
  bool line() const  { return (red_line || white_line); }
  bool red() const   { return (red_line || red_loop); };
  bool white() const { return (white_line || white_loop); };

  bool won_by_loop() const {
    return ( red() ? red_loop : white() ? white_loop : false );
  };

protected:
  bool scan_forced();

  void get_around_colors(const int, const int, int&, int&, int&, int&);
  bool trace_loop(const int, const int, const int, const int);
  bool trace_loop(const int, const int);
  bool trace_line(const int, const int, const int, const int);

  bool is_prohibited_3(const int x, const int y);
  bool is_consistent_placement(int x, int y, char tile);
  bool is_line_color_connected(int x, int y);

  int opposite_color(const int);

  std::map<xy, char> board;
  std::map<xy, char> board_color;
  std::map<xy, char> board_marks;

 
  // char board[BOARD_MAX][BOARD_MAX];
  // char board_color[BOARD_MAX][BOARD_MAX];
  // char board_marks[BOARD_MAX][BOARD_MAX];

  int left, right, top, bottom;
  bool white_loop, red_loop, white_line, red_line;

  bool silent;
  
  friend std::ostream& operator<<(std::ostream&, const trax&);
};


std::ostream& operator<<(std::ostream&, const move&);
std::ostream& operator<<(std::ostream&, const trax&);

#endif

