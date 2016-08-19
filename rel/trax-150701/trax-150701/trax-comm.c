/*
    Trax serial / TCP communication
        Original writen by Prof. A. Kojima @ Hiroshima City Univ.
 */


//#define DEBUG

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <termios.h>
#include <string.h>
#include <fcntl.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

#define BUF_SIZE 64

#define USE_SERIAL_AUTO 0
#define USE_SERIAL      1
#define USE_TCP         2

#define TRUE (1==1)
#define FALSE (2==1)

#define PLAYER_WHITE 0
#define PLAYER_BLACK 1

char* serial_devs[100] = { // List of serial devices to be scanned
  "/dev/cuaU0",   "/dev/cuaU1",   "/dev/cuaU2",   "/dev/cuaU3",
  "/dev/ttyUSB0", "/dev/ttyUSB1", "/dev/ttyUSB2", "/dev/ttyUSB3",
  "/dev/ttys006", "/dev/ttys007", NULL };

int move_timeout = 10;  // 10 sec.
int no_player_code = FALSE;
int wait_mode = 0;
int verbose_level = 0;

struct {
  int mode; // USE_SERIAL or USE_TCP
  int fd;
  char* dev;
  char code[3];
} player[2];

// ------------------------------------------------------------

char* b_or_w(int p){
  if (p==PLAYER_WHITE) return "White";
  return "Black";
}

void error_comm(){
  printf("*E_communication\n");
  fflush(stdout);
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
      fprintf(stderr, "remaining time: %d\n", timeout_ms);

    timeout.tv_sec = timeout_ms / 1000;
    timeout.tv_usec = (timeout_ms % 1000) * 1000;

    FD_ZERO(&read_fds);
    FD_SET(fd, &read_fds);
    if (select(fd+1, &read_fds, &write_fds, &except_fds, &timeout) == 1){
      read(fd, &buf[got], 1);
    } else {
      fprintf(stderr, "timeout!\n");
      got = 0;
      break; // timeout
    }
    write(1, NULL, 0); // this causes SIGPIPE when stdout has closed

    // skip first 0x0d and 0x0a
    if (got == 0 && (buf[got] == 0x0d || buf[got] == 0x0a)) continue;
    
    if (buf[got  ] == 0x0d) buf[got] = 0x0a; // convert 0x0d -> 0x0a
    if (buf[got++] == 0x0a) break;
  } while(got < len);

  gettimeofday(&stop, NULL);
  elapsed_time = timeval_subtract(&stop, &start);
  remaining_time = move_timeout * 1000 - elapsed_time; // in msec.
  if (verbose_level > 1){
    fprintf(stderr, "read %d bytes in %d msec.\n", got, elapsed_time);
  }


  if (w!=0){
    usleep(remaining_time * 1000); // usleep in microseconds

    if (verbose_level > 1){
      gettimeofday(&stop, NULL);
      elapsed_time = timeval_subtract(&stop, &start);
      fprintf(stderr, "elapsed time: %d\n", elapsed_time);
    }
  }
  return got;
}

// ------------------------------------------------------------

void send_player(int p, char *buf)
{
  int len = strlen(buf);
  if (write(player[p].fd, buf, len) != len) {
    fprintf(stderr, "Failed to send data : [%s] to %s.\n", buf, b_or_w(p));
    error_comm(); // Error: Critical communication problem
  }
}

int recv_code(int p, char *buf){
  if(no_player_code){
    sprintf(buf, "0%d", p);
    strcpy(player[p].code, buf);
    return 0;
  }
  send_player(p, "-T\n");
  
  if(read_all(player[p].fd, 3, buf, 0) < 2){
    fprintf(stderr, "Failed to receive player code from %s.\n", b_or_w(p));
    return -1;
  }
  buf[2] = '\0'; // terminate string
  strcpy(player[p].code, buf);
  return 0;
}


void recv_player(int p, char *buf){
  int got = read_all(player[p].fd, 16, buf, wait_mode);

  buf[got] = '\0'; // terminate string
  if (got < 4 || got > 6 || buf[got - 1] != 0x0a) {
    fprintf(stderr, "Failed to receive data : got %d [%s] from %s.\n", got, buf, b_or_w(p));
    
    printf("*E_timeout\n");
    fflush(stdout);
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
    fprintf(stderr, "illegal tcp port %s\n", port_str);
    error_comm(); // Error: Critical communication problem
  }
  fprintf(stderr, "%s player : TCP port %d\n", b_or_w(p), tcp_port);
  
  // open tcp socket
  if ((sock_fd = socket(AF_INET, SOCK_STREAM, 0)) < 0){
    fprintf(stderr, "Failed to open socket\n");
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
    fprintf(stderr, "Failed to bind socket\n");
    error_comm(); // Error: Critical communication problem
  }
  
  if (listen(sock_fd, 1) < 0) {
    fprintf(stderr, "Failed to listen socket\n");
    error_comm(); // Error: Critical communication problem
  }
  
  if ((player[p].fd = accept(sock_fd, NULL, NULL)) < 0) {
    fprintf(stderr, "Failed to accept socket\n");
    error_comm(); // Error: Critical communication problem
  }
}

int open_serial(int p, char *dev_str)
{
  struct termios new_tio;
  //struct termios prev_tio;
  
  player[p].mode = USE_SERIAL;
  
  fprintf(stderr, "%s player : Serial port %s\n", b_or_w(p), dev_str);

  // open serial device
  if ((player[p].fd = open(dev_str, O_RDWR | O_NOCTTY)) < 0 ) {
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

// ------------------------------------------------------------

void usage()
{
  fprintf(stderr,
	  "usage: trax-comm [options] [[user1] user2]]\n"
	  "  -o: original / official protocol (without player code)\n"
	  "  -t: timeout (seconds) default: 10\n"
	  "  -r: User 2 as white, user 1 as black\n"
	  "  -w: Wait mode: sleep until timelimit even if client answers earier\n"
	  "  -v: be verbose (-vv, -vvv for more)\n"
	  "  user1 and user2 : serial device (/dev/ttyXX), serial autoscan (auto) or TCP port (100XX)\n");
}


// getopt stuff
extern char *optarg;
extern int optind;

int main(int argc, char *argv[])
{
  char buf[BUF_SIZE];
  int i;
  int p = 0;

  int ch;
  int reverse = FALSE;
  int dev = 0;
  
  while ((ch = getopt(argc, argv, "orvwt:")) != -1) {
    switch (ch) {
    case 'o':
      no_player_code = TRUE;
      break;
    case 'r':
      reverse = TRUE;
      break;
    case 't':
      move_timeout = atoi(optarg);            
      break;
    case 'v':
      verbose_level++;
      break;
    case 'w':
      wait_mode=1;
      break;
    case 'h':
    default:
      usage();
      exit(0);
    }
  }
  argc -= optind;
  argv += optind;

  move_timeout = (move_timeout <= 0) ? 1 : move_timeout;

  if(verbose_level>0){
    fprintf(stderr,
	    "Verbose level: %d\n"
	    "Timeout: %d sec.\n", verbose_level, move_timeout);
  }
  
  // Get user serial/TCP port options
  player[0].mode = player[1].mode = USE_SERIAL_AUTO;
  for (i = 0; i < argc; i++) {
    player[i].dev = argv[p];
    player[i].mode = ( (argv[i][0] == '1') ? USE_TCP :
		       (argv[i][0] == 'a') ? USE_SERIAL_AUTO :
		       USE_SERIAL );
    p++;
  }

  // Swap players if '-r' given
  if (reverse) {
    int a; char *b;
    a=player[1].mode; player[1].mode=player[0].mode; player[0].mode=a;
    b=player[1].dev;  player[1].dev =player[0].dev;  player[0].dev =b;
  }

  // Open serial / tcp ports
  for (i=0; i<2; i++){
    switch (player[i].mode) {
    case USE_SERIAL_AUTO:
      if (no_player_code) {
	fprintf(stderr, "No autoscan support in original protocol!\n");
	error_comm(); // Error: Critical communication problem: scan failed
      }
      while(serial_devs[dev]!=NULL){
	printf("Trying %s\n", serial_devs[dev]);
	if (open_serial(i, serial_devs[dev])<0){ dev++; continue; } // can't open
	if (recv_code(i, buf)>=0){
	  printf("OK! code=%s\n", buf);
	  break;
	} else {
	  dev++; close(player[i].fd); continue;
	}
      }
      if (serial_devs[dev]==NULL){
	fprintf(stderr, "No more serial device found.\n");
	error_comm(); // Error: Critical communication problem: scan failed
      }
      dev++; // increment for next player
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

  // Header
  printf("Trax\n");
  printf("%s vs %s\n", player[0].code, player[1].code);
  fflush(stdout);

  // Game start
  send_player(PLAYER_BLACK, "-B\n");
  send_player(PLAYER_WHITE, "-W\n");
  
  // Main game loop
  p = PLAYER_WHITE;
  for (;;) {
    recv_player(p, buf);
    printf("%s", buf);
    fflush(stdout);
    // This version does not check the move data.

    p = (p == PLAYER_WHITE) ? PLAYER_BLACK : PLAYER_WHITE;
    send_player(p, buf);
  }

  // not reached

  // This version does not call close(fd). It assumes killed and closed by OS.

  return 0;
}
