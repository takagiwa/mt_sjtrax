// 
// two-way-socket for trax and traxfig
//                                         by A.Kojima
//
// two ports -> stdout adaptor program for ICFPT2015 design contest trax protocol
//
// (ex1) two serial ports -> stdout
// ./two-way-socket /dev/ttyS0 /dev/ttyS1 | ./trax
//
// (ex2) two tcp ports -> stdout
// ./two-way-socket 10000 10001 | ./trax
//
// (ex3) serial port & tcp port -> stdout
// ./two-way-socket /dev/ttyS0 10000 | ./trax
//
// (ex4) use traxfig
// ./two-way-socket /dev/ttyS0 /dev/ttyS1 | ./interactive_traxfig.pl
//

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

#define USE_SERIAL 1
#define USE_TCP    2

#define PLAYER_WHITE 0
#define PLAYER_BLACK 1

struct {
  int mode; // USE_SERIAL or USE_TCP
  int fd;
} player[2];

////////////////////////////////////////////////////////////////////////////////////
// read_all() from blokus-host.c by Osana

//int move_timeout = 1; // 1 sec.
int move_timeout = 10000; // 10000 sec.

int timeval_subtract(struct timeval *a, struct timeval *b){
  // return a-b in milliseconds
  
  return (a->tv_usec - b->tv_usec)/1000 + (a->tv_sec - b->tv_sec)*1000;
}

int read_all(int fd, int len, char* buf){
  // read LEN bytes from FD, but without CR and LF.
  int got = 0;
  struct timeval start, timelimit, stop;
  fd_set read_fds, write_fds, except_fds;

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
#ifdef DEBUG
    fprintf(stderr, "remaining time: %d\n", timeout_ms);
#endif

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

#if 1 // for trax by A.Kojima
#ifdef DEBUG
    fprintf(stderr, "buf[%d]=0x%02x, ", got, buf[got]);
#endif
    if (got == 0 && (buf[got] == 0x0d || buf[got] == 0x0a)) {
      continue; // skip first 0x0d and 0x0a
    }
    if (buf[got] == 0x0d) {
      buf[got] = 0x0a; // convert 0x0d -> 0x0a
#ifdef DEBUG
      fprintf(stderr, "convert 0x0d -> 0x0a\n");
#endif
    }
    if (buf[got++] == 0x0a) {
      break;
    }
#else // original for blokus
    if(buf[got] != 0x0d && buf[got] != 0x0a) got++;
#endif
  } while(got < len);

  gettimeofday(&stop, NULL);
#ifdef DEBUG
  fprintf(stderr, "read %d bytes in %d msec.\n", got, timeval_subtract(&stop, &start));
#endif
  return got;
}
////////////////////////////////////////////////////////////////////////////////////

void recv_player(int p, char *buf)
{
  int got = read_all(player[p].fd, 16, buf);
  buf[got] = '\0'; // terminate string
  if (got < 4 || got > 6 || buf[got - 1] != 0x0a) {
    fprintf(stderr, "Failed to receive data : got %d [%s] from %s.\n", got, buf, ((p == PLAYER_WHITE) ? "White" : "Black"));
    exit(1);
  }
}

void send_player(int p, char *buf)
{
  int len = strlen(buf);
  if (write(player[p].fd, buf, len) != len) {
    fprintf(stderr, "Failed to send data : [%s] to %s.\n", buf, ((p == PLAYER_WHITE) ? "White" : "Black"));
    exit(1);
  }
}

void open_tcp(int p, char *port_str)
{
  int tcp_port; // use tcp port 10000 - 10010
  int sock_fd, sock_opt;
  struct sockaddr_in sock_addr;
  
  player[p].mode = USE_TCP;
  
  tcp_port = atoi(port_str);
  if (tcp_port < 10000 || tcp_port > 10010) {
    fprintf(stderr, "illegal tcp port %s\n", port_str);
    exit(1);
  }
  fprintf(stderr, "%s player : TCP port %d\n", ((p == PLAYER_WHITE) ? "White" : "Black"), tcp_port);
  
  // open tcp socket
  if ((sock_fd = socket(AF_INET, SOCK_STREAM, 0)) < 0){
    fprintf(stderr, "Failed to open socket\n");
    exit(1);
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
    exit(1);
  }
  
  if (listen(sock_fd, 1) < 0) {
    fprintf(stderr, "Failed to listen socket\n");
    exit(1);
  }
  
  if ((player[p].fd = accept(sock_fd, NULL, NULL)) < 0) {
    fprintf(stderr, "Failed to accept socket\n");
    exit(1);
  }
}

void open_serial(int p, char *dev_str)
{
  struct termios new_tio;
  //struct termios prev_tio;
  
  player[p].mode = USE_SERIAL;
  
  fprintf(stderr, "%s player : Serial port %s\n", ((p == PLAYER_WHITE) ? "White" : "Black"), dev_str);

  // open serial device
  if ((player[p].fd = open(dev_str, O_RDWR | O_NOCTTY)) < 0 ) {
    fprintf(stderr, "Failed to open serial device %s\n", dev_str);
    exit(1);
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
}

void usage()
{
  fprintf(stderr, "usage : two-way-socket [-t <time(sec.)>] <white serial_device or tcp_port> <black serial_device or tcp_port>\n");
  fprintf(stderr, "  ex1 : two-way-socket /dev/ttyS0 /dev/ttyS1\n");
  fprintf(stderr, "  ex2 : two-way-socket 10000 10001\n");
  fprintf(stderr, "  ex3 : two-way-socket /dev/ttyS0 10000\n");
  fprintf(stderr, "  ex4 : two-way-socket 10000 /dev/ttyS0\n");
  fprintf(stderr, "  ex5 : two-way-socket -t 1 /dev/ttyS0 /dev/ttyS1\n");
  fprintf(stderr, "tcp_port : 10000 - 10010\n");
  fprintf(stderr, "default thinking time : 10000 second\n");
}

int main(int argc, char *argv[])
{
  char buf[BUF_SIZE];
  int i;
  int p = 0;

  for (i = 1; i < argc; i++) {
    if (strcmp(argv[i], "-t") == 0) {
      move_timeout = atoi(argv[++i]);
    } else if (argv[i][0] == '1') { // if "1..." then use tcp port, else use serial port
      open_tcp(p++, argv[i]);
    } else {
      open_serial(p++, argv[i]);
    }
  }
  if (p != 2 || move_timeout <= 0) { 
    usage();
    exit(1);
  }

  send_player(PLAYER_BLACK, "-B\n");
  send_player(PLAYER_WHITE, "-W\n");
  
  // game loop
  p = PLAYER_WHITE;
  for (;;) {
    //fprintf(stderr, "%s turn.\n", (p == PLAYER_WHITE) ? "White" : "Black");

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

