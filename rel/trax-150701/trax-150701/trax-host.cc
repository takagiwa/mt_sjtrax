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
#include <fstream>
#include <iomanip>

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

int log_serial(){
  FILE* seqfile;
  int seq = 0;

  seqfile = fopen("log-seq", "r");
  if (seqfile != NULL){
    fscanf(seqfile, "%d", &seq);
    fclose(seqfile);
  }

  seq++;
  seqfile = fopen("log-seq", "w");
  fprintf(seqfile, "%d", seq);
  fclose(seqfile);

  return seq;
}

// ----------------------------------------------------------------------

int main(int argc, char *argv[]){
  trax t;
  bool enable_log = false;

  if (argc==2 && std::string(argv[1])=="-l") enable_log = true;
  
  t.clear_board();

  // first move is either "@0/" or "@0+"
  std::string m, mm;
  
  bool preamble = true;
  int preamble_lines = 0;
  
  int turn = 0;
  int p = 1;

  mm="";
  player1 = "01";
  player2 = "02";

  std::ofstream log_file;
  
  //  std::cout << t;
  while ( std::cin >> m ){
    if (preamble){
      preamble_lines++;

      if(m =="vs") player1 = mm;
      if(mm=="vs") player2 = m;
      mm=m;
      
      if (m[0]=='@' || m[0]=='*'){
	preamble=false;
	std::cout << "Players: " << player1 << " / " << player2 << std::endl;

	if (enable_log){
	  char buf[256];
	  sprintf(buf, "%04d-%s-%s.log",
		  log_serial(), player1.c_str(), player2.c_str());

	  log_file.open(buf);
	  log_file << "Trax\n"
		   << player1 << " vs " << player2 << "\n";
	}
      }
    }

    if (!preamble){
      if (enable_log) log_file << m << "\n";
      
      std::cout << "Turn " << ++turn
		<< " (player " << p << ": " << player(p) << "): ";

      bool violation = false;

      if(m[0]=='*'){ // communication error
        violation = true;
       
        std::cout << m << std::endl;
        if (m=="*E_timeout")
          std::cout << "**** Timeout ****" << std::endl;
        
        if (m=="*E_communication"){
          std::cout << "==== Communication Error!" << std::endl;
          return -1;
        }
        
      } else {
        // may be a valid move
        move mo = move(m);
        std::cout << m << "[" << mo << "] ";
      
        // place a move
        if(!t.place(mo, turn)) violation = true;

        std::cout << t;
        if (t.is_board_consistent()){
          if(t.loop() || t.line()){
            int winner = p;

            switch(winner){
            case 1:
              if (t.red() && !t.white()) winner=2;
              break;
            case 2:
              if (t.white() && !t.red()) winner=1;
              break;
            }
            std::cout << "==== " << player_name(winner) << "(" << player(winner)
                      << ") GOT A " << (t.loop() ? "LOOP" : "LINE")
                      << " in " << player_name(p) << "(" << player(p)
                      << ")'s turn !" << std::endl;
            //  std::cout << "==== " << player_name(winner) << " won the game.\n";
            return 0;
          }
        }
        else {
          violation = true;
        }
      }

      if (violation){
	std::cout << "---- VIOLATION ! ----\n";
	std::cout << "==== " << player_name(p)
                  << " lost the game by violation.\n";
	return -1;
      }

      std::cout << "Going to next turn." << std::endl;
      
      t.clear_marks();
      p = (p==2) ? 1 : 2;
    }
  }
}
