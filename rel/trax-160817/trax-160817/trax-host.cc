/*
  Trax serial / TCP communication
  Original writen by Prof. A. Kojima @ Hiroshima City Univ.
*/


//#define DEBUG

#include <fstream>
#include <iostream>
#include <vector>
#include <string>

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <termios.h>
#include <fcntl.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

#include "trax.h"

#define BUF_SIZE 64

enum comtypes { USE_SERIAL_AUTO, USE_SERIAL, USE_TCP };

#define TRUE (1==1)
#define FALSE (2==1)

#define PLAYER_WHITE 0
#define PLAYER_BLACK 1

std::string serial_devs[100] = { // List of serial devices to be scanned
  "/dev/cuaU0",   "/dev/cuaU1",   "/dev/cuaU2",   "/dev/cuaU3",
  "/dev/ttyUSB0", "/dev/ttyUSB1", "/dev/ttyUSB2", "/dev/ttyUSB3", "" };

// int move_timeout = 10;  // 10 sec.
int move_timeout = 1; // 1 sec.
bool no_player_code = false;
int wait_mode = 0;
int verbose_level = 0;

struct {
  comtypes mode; // USE_SERIAL or USE_TCP
  int fd;
  char* dev;
  std::string code;
} player[2];

// ------------------------------------------------------------

std::string b_or_w(int p){
  if (p==PLAYER_WHITE) return "White";
  return "Black";
}

void error_comm(){
  std::cerr << "==== Communication Error!" << std::endl;
  exit(-1);
}

// ------------------------------------------------------------

int timeval_subtract(struct timeval *a, struct timeval *b){
  // return a-b in milliseconds
  
  return (a->tv_usec - b->tv_usec)/1000 + (a->tv_sec - b->tv_sec)*1000;
}

int read_all(int fd, int len, char* buf, int w){
  // read LEN bytes from FD, but without CR and LF. Ends on LF.
  int got = 0;
  struct timeval start, timelimit, stop;
  fd_set read_fds, write_fds, except_fds;
  int elapsed_time, remaining_time;

  FD_ZERO(&write_fds);
  FD_ZERO(&except_fds);

  gettimeofday(&start, NULL);
  timelimit = start;
  timelimit.tv_sec = timelimit.tv_sec + move_timeout;

  do {
    struct timeval now, timeout;
    int timeout_ms;

    gettimeofday(&now, NULL);
    timeout_ms = timeval_subtract(&timelimit, &now);
    if (timeout_ms <= 0) break; // no remaining time
    if (verbose_level > 2)
      std::cerr << "remaining time: " << timeout_ms << std::endl;

    timeout.tv_sec = timeout_ms / 1000;
    timeout.tv_usec = (timeout_ms % 1000) * 1000;

    FD_ZERO(&read_fds);
    FD_SET(fd, &read_fds);
    if (select(fd+1, &read_fds, &write_fds, &except_fds, &timeout) == 1){
      read(fd, &buf[got], 1);
    } else {
      std::cerr << "timeout!" << std::endl;
      got = 0;
      break; // timeout
    }
    //    write(1, NULL, 0); // this causes SIGPIPE when stdout has closed

    // skip first 0x0d and 0x0a
    if (got == 0 && (buf[got] == 0x0d || buf[got] == 0x0a)) continue;
    
    if (buf[got  ] == 0x0d) buf[got] = 0x0a; // convert 0x0d -> 0x0a
    if (buf[got++] == 0x0a) break;
  } while(got < len);

  gettimeofday(&stop, NULL);
  elapsed_time = timeval_subtract(&stop, &start);
  remaining_time = move_timeout * 1000 - elapsed_time; // in msec.
  if (verbose_level > 1){
    std::cerr << "read " << got << " bytes in "
              << elapsed_time << " msec." << std::endl;
  }


  if (w!=0){
    usleep(remaining_time * 1000); // usleep in microseconds

    if (verbose_level > 1){
      gettimeofday(&stop, NULL);
      elapsed_time = timeval_subtract(&stop, &start);
      std::cerr << "elapsed time: " << elapsed_time << std::endl;
    }
  }
  return got;
}

// ------------------------------------------------------------

void send_player(int p, std::string buf)
{
  int len = buf.length();
  if (write(player[p].fd, buf.c_str(), len) != len) {
    std::cerr << "Failed to send data : ["
              << buf << "] to " << b_or_w(p) << "." << std::endl;
    error_comm(); // Error: Critical communication problem
  }
}

int recv_code(int p, char *buf){
  if(no_player_code){
    sprintf(buf, "0%d", p);
    player[p].code = buf;
    return 0;
  }
  send_player(p, "-T\n");
  
  if(read_all(player[p].fd, 3, buf, 0) < 2){
    std::cerr << "Failed to receive player code from "
              << b_or_w(p) << std::endl;
    return -1;
  }
  buf[2] = '\0'; // terminate string
  player[p].code = buf;
  return 0;
}


void recv_player(int p, char *buf){
  int got = read_all(player[p].fd, 16, buf, wait_mode);

  buf[got] = '\0'; // terminate string
  if (got < 4 || got > 6 || buf[got - 1] != 0x0a) {
    std::cerr << "Failed to receive data : got " << got
              << " [" << buf << "] from " << b_or_w(p) << "." << std::endl; 

    std::cerr << "**** Timeout ****" << std::endl; // FIXME
    exit(1); // Error: Player Timeout
  }
}


void open_tcp(int p, char *port_str)
{
  int tcp_port; // use tcp port 10000 - 10010
  int sock_fd, sock_opt;
  struct sockaddr_in sock_addr;
  
  player[p].mode = USE_TCP;
  
  tcp_port = atoi(port_str);
  if (tcp_port < 10000 || tcp_port > 10102) {
    std::cerr << "Illegal TCP port " << port_str << std::endl;
    error_comm(); // Error: Critical communication problem
  }
  std::cerr << b_or_w(p) << " player : TCP port " << tcp_port << std::endl;
  
  // open tcp socket
  if ((sock_fd = socket(AF_INET, SOCK_STREAM, 0)) < 0){
    std::cerr << "Failed to open socket" << std::endl;
    error_comm(); // Error: Critical communication problem
  }
  
  sock_opt = 1;
  setsockopt(sock_fd, SOL_SOCKET, SO_REUSEADDR, &sock_opt, sizeof(sock_opt));
#ifdef SO_REUSEPORT
  setsockopt(sock_fd, SOL_SOCKET, SO_REUSEPORT, &sock_opt, sizeof(sock_opt));
#endif
  
  bzero((void*)&sock_addr, sizeof(sock_addr));
  sock_addr.sin_family = AF_INET;
  sock_addr.sin_addr.s_addr = INADDR_ANY;
  sock_addr.sin_port = htons(tcp_port);
  
  if (bind(sock_fd, (struct sockaddr *)&sock_addr, sizeof(sock_addr)) < 0){
    std::cerr << "Failed to bind socket" << std::endl;
    error_comm(); // Error: Critical communication problem
  }
  
  if (listen(sock_fd, 1) < 0) {
    std::cerr << "Failed to listen socket" << std::endl;
    error_comm(); // Error: Critical communication problem
  }
  
  if ((player[p].fd = accept(sock_fd, NULL, NULL)) < 0) {
    std::cerr << "Failed to accept socket" << std::endl;
    error_comm(); // Error: Critical communication problem
  }
}

int open_serial(int p, std::string dev_str)
{
  struct termios new_tio;
  //struct termios prev_tio;
  
  player[p].mode = USE_SERIAL;

  std::cerr << b_or_w(p) << " player : serial port " << dev_str << std::endl;

  // open serial device
  if ((player[p].fd = open(dev_str.c_str(), O_RDWR | O_NOCTTY)) < 0 ) {
    return -1;
  }
  
  //tcgetattr(player[p].fd, &prev_tio); // XXX : This version does not restore the previous attribute.
  tcflush(player[p].fd, TCIOFLUSH);
  
  memset(&new_tio, 0, sizeof(new_tio));
  cfsetispeed(&new_tio, B19200);
  cfsetospeed(&new_tio, B19200);
  new_tio.c_cflag |= CS8 | CLOCAL | CREAD;
  new_tio.c_iflag |= IGNPAR;

  tcsetattr(player[p].fd, TCSANOW, &new_tio);
  tcflush(player[p].fd, TCIOFLUSH);
  return 0;
}

int next_dev(int d, int reverse_search){
  if (reverse_search) return d-1;
  return d+1;
}

bool no_more_dev(int d, int reverse_search){
  if ( ( reverse_search && d==-1) ||
       (!reverse_search && serial_devs[d]=="") ) return true;

  return false;
}

// ------------------------------------------------------------
// Logging stuff

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

void setup_log(std::ofstream& log_file){
  char buf[256];
  
  sprintf(buf, "%04d-%s-%s.log",
          log_serial(), player[0].code.c_str(), player[1].code.c_str());
    
  log_file.open(buf);
}

// ------------------------------------------------------------
// Startup staff / help message

void usage()
{
  std::cerr 
    << "usage: trax-comm [options] [[user1] user2]]" << std::endl
    << "  -R: replay: input from log file (logging disabled)" << std::endl
    << "  -l: enable logging" << std::endl
    << "  -o: original / official protocol (without player code)" << std::endl
    << "  -t: timeout (seconds) default: 10" << std::endl
    << "  -r: User 2 as white, user 1 as black" << std::endl
    << "  -w: Wait mode: sleep until timelimit even if client answers earier" << std::endl
    << "  -v: be verbose (-vv, -vvv for more)" << std::endl
    << "  user1 and user2 : serial device (/dev/ttyXX), serial autoscan (auto) or TCP port (100XX)" << std::endl;
}

void setup_port_options(int argc, char* argv[], bool reverse,
                        bool& reverse_search,
                        bool& both_auto, int& dev){
  int p = 0;

  // Get user serial/TCP port options
  player[0].mode = player[1].mode = USE_SERIAL_AUTO;
  for (int i = 0; i < argc; i++) {
    player[i].dev = argv[p];
    player[i].mode = ( (argv[i][0] == '1') ? USE_TCP :
		       (argv[i][0] == 'a') ? USE_SERIAL_AUTO :
		       USE_SERIAL );
    p++;
  }

  // Swap players if '-r' given
  if (reverse) {
    comtypes a; char *b;
    a=player[1].mode; player[1].mode=player[0].mode; player[0].mode=a;
    b=player[1].dev;  player[1].dev =player[0].dev;  player[0].dev =b;
  }

  // auto vs auto
  if (player[0].mode == USE_SERIAL_AUTO &&
      player[1].mode == USE_SERIAL_AUTO ){
    both_auto = false;
  }

  if (both_auto && reverse){
    while (serial_devs[dev]!="") dev++;
    dev--;
    reverse_search = true;
  }
}

void open_devs(int &dev, bool& reverse_search){
  char buf[BUF_SIZE];

  // Open serial / tcp ports
  for (int i=0; i<2; i++){
    switch (player[i].mode) {
    case USE_SERIAL_AUTO:
      if (no_player_code) {
        std::cerr << "No autoscan support in original protocol!" << std::endl;
        error_comm(); // Error: Critical communication problem: scan failed
      }
      while( !no_more_dev(dev, reverse_search) ){
        std::cerr << "Trying " << serial_devs[dev] << std::endl;
        if (open_serial(i, serial_devs[dev])<0){
          dev = next_dev(dev, reverse_search);
          continue;
        } // can't open
        if (recv_code(i, buf)>=0){
          std::cerr << "OK! code=" << buf << std::endl;
          break;
        } else {
          dev = next_dev(dev, reverse_search);
          close(player[i].fd);
          continue;
        }
      }
      if (no_more_dev(dev, reverse_search)){
        std::cerr << "No more serial device found." << std::endl;
        error_comm(); // Error: Critical communication problem: scan failed
      }
      dev = next_dev(dev, reverse_search);
      break;
	
    case USE_SERIAL:
      if (open_serial(i, player[i].dev)<0) exit(1); // can't open
      if (recv_code(i, buf)<0) error_comm(); // Error: player code timeout
      break;
	
    case USE_TCP:
      open_tcp(i, player[i].dev);
      if (recv_code(i, buf)<0) error_comm(); // Error: player code timeout
      break;
    }
  }
}

// ------------------------------------------------------------

void game_won(trax& t, int p){
  int winner = p;
        
  switch(winner){
  case PLAYER_WHITE:
    if (t.red() && !t.white()) winner=PLAYER_BLACK;
    break;
  case PLAYER_BLACK:
    if (t.white() && !t.red()) winner=PLAYER_WHITE;
    break;
  }
  std::cout << "==== " << player[winner].code << "("
            << (winner==PLAYER_WHITE ? "white" : "red")
            << ") GOT A " << (t.won_by_loop() ? "LOOP" : "LINE")
            << " in " << player[p].code << "("
            << (p==PLAYER_WHITE ? "white" : "red")
            << ")'s turn !" << std::endl;

}

// ------------------------------------------------------------

// getopt stuff
extern char *optarg;
extern int optind;

int main(int argc, char *argv[])
{
  char buf[BUF_SIZE];

  int ch;
  bool reverse = false;

  bool both_auto = false;
  bool reverse_search = false;

  bool enable_log = false;
  bool replay_mode = false;
  
  while ((ch = getopt(argc, argv, "lRorvwt:")) != -1) {
    switch (ch) {
    case 'l': enable_log     = true;         break; // not implemented yet
    case 'R': replay_mode    = true;         break; // not implemented yet
    case 'o': no_player_code = true;         break;
    case 'r': reverse        = true;         break;
    case 't': move_timeout   = atoi(optarg); break;
    case 'v': verbose_level++;               break;
    case 'w': wait_mode = 1;                 break;
    case 'h':
    default:
      usage();
      exit(0);
    }
  }
  argc -= optind;
  argv += optind;

  if (replay_mode) enable_log = false;
  move_timeout = (move_timeout <= 0) ? 1 : move_timeout;

  if(verbose_level>0){
    std::cerr << "Verbose level: " << verbose_level
              << "Timeout: " << move_timeout << " sec." << std::endl;
  }

  // default codes
  player[0].code = "01";
  player[1].code = "02";
  
  // setup game 
  std::string m, mm;
  
  if (!replay_mode){
    // TCP / serial Setup
    int dev = 0;
    setup_port_options(argc, argv, reverse, reverse_search, both_auto, dev);
    open_devs(dev, reverse_search);
  } else {
    // Replay mode: read preamble
    mm = "";
    while (std::cin >> m){
      if(m =="vs") player[0].code = mm;
      if(mm=="vs") player[1].code = m;
      mm=m;

      if (m[0]=='@' || m[0]=='*') break;
    }
  }

  // Player code is ready here
  std::cout << "Players: " << player[0].code << " / " << player[1].code << std::endl;

  // setup log
  std::ofstream log_file;
  if (enable_log){
    setup_log(log_file);
    log_file << "Trax" << std::endl
           << player[0].code << " vs " << player[1].code << std::endl;
  }

  // ------------------------------

  trax t;
  t.clear_board();
  
  // Game start
  if (!replay_mode){
    send_player(PLAYER_BLACK, "-B\n");
    send_player(PLAYER_WHITE, "-W\n");
  }
  
  // Main game loop
  int p = PLAYER_WHITE;

  int turn = 0;
  
  for (;;) {
    if (!replay_mode)
      recv_player(p, buf);
    else
      strcpy(buf, m.c_str());

    char buf2[100];
    strcpy(buf2, buf);
    for(int pos=0; buf2[pos]!=0; pos++) // remove trailing CR/LF
      if(buf2[pos]=='+' || buf2[pos]=='/' || buf2[pos]=='\\') buf2[pos+1]=0;
    
    move mo = move(buf);

    // show move
    std::cout << "Turn " << ++turn
              << " (player " << p << ": "
              << (p==PLAYER_WHITE ? "white" : "red") << "): "
              << buf2 << "[" << mo << "] ";

    if (enable_log) log_file << buf2 << std::endl;
    
    // place a move
    bool violation = false;
    
    if(!t.place(mo, turn)) violation = true;

    std::cout << t;
    if (t.is_board_consistent()){
      if(t.loop() || t.line()){
        game_won(t, p);
        return 0;
      }
    } else {
      violation = true;
    }
    
    if (violation){
      std::cout << "---- VIOLATION ! ----\n";
      std::cout << "==== " << player[p].code
                << " lost the game by violation.\n";
      return -1;
    }
    
    std::cout << "Going to next turn." << std::endl;
    
    t.clear_marks();
    
    p = (p == PLAYER_WHITE) ? PLAYER_BLACK : PLAYER_WHITE;

    if (!replay_mode)
      send_player(p, buf);
    else
      std::cin >> m;
  }


  return 0;
}




