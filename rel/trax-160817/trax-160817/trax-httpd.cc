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
#include <string>

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <netinet/in.h>

#define BUFSIZE 500

FILE* accept_connection(int sock){
  int sock_fd;
  FILE* sock_file;

  sock_fd = accept(sock, NULL, NULL);
  if(sock_fd == -1){
    perror("accept() failed! ");
    exit(-1);
  }

  sock_file = fdopen(sock_fd, "w+"); // R/W
  setvbuf(sock_file, NULL, _IONBF, 0);

  return sock_file;
}

int http_header(FILE* sock_file){
  char buf[BUFSIZE];
  int retval = 0;

  while(fgets(buf, BUFSIZE-1, sock_file)){
    printf("* %s\n", buf);
    if(strncmp(buf, "GET /favicon", 12)==0 ){ retval = -1; break; }
    if(strncmp(buf, "GET", 3)==0){ retval = 0; break; }
  }

  do {
    fgets(buf, BUFSIZE-1, sock_file);
  } while(strlen(buf) != 2);


  fprintf(sock_file,
          "HTTP/1.1 200 OK\x0d\x0a"\
          "Content-Type: text/html\x0d\x0a"\
          //        "Transfer-Encoding: chunked\x0d\x0a"
          "\x0d\x0a");

  return retval;
}

int main(){
  int sock, on;
  struct sockaddr_in s_addr;
  FILE *sock_file;
  std::ifstream html_file;

  char buf[BUFSIZE+1];
  std::string buf2;
  char *trax_env;
  std::string html_filename;
   
  sock = socket(AF_INET, SOCK_STREAM, 0);
  if (sock<0){
    perror("opening stream socket failed! ");
    exit(-1);
  }
  on = 1;
  setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, (char*)&on, sizeof(on));
#if defined (__FreeBSD__)  || (__APPLE__)
  setsockopt(sock, SOL_SOCKET, SO_REUSEPORT, (char*)&on, sizeof(on));
#endif

  bzero((void*)&s_addr, sizeof(s_addr));

  s_addr.sin_family = AF_INET;
  s_addr.sin_addr.s_addr = INADDR_ANY;
  s_addr.sin_port = htons(11000);

  if(bind(sock, (struct sockaddr *)&s_addr, sizeof(s_addr)) < 0){
    perror("bind socket failed! ");
    exit(-1);
  }

  listen(sock, 0); // only 1 client per port
  printf("Waiting on TCP port %d...\n", 11000);

  // find HTML file (default trax.html)
  trax_env = getenv("TRAX");
  html_filename = ( (trax_env == NULL) ? "trax.html" :
		    ((std::string)trax_env + "/trax.html") );

  html_file.open(html_filename.c_str());
  if (!html_file){
    perror("trax.html ");
    exit(-1);
  }

  // send HTML file for first time
  sock_file = accept_connection(sock);
  http_header(sock_file);

  while(getline(html_file, buf2)){
    fprintf(sock_file, "%s\n", buf2.c_str());
  }

  fclose(sock_file);
  html_file.close();

  
  // send board status
  sock_file = accept_connection(sock);

  http_header(sock_file);
  do {
    if (fgets(buf, BUFSIZE, stdin) == NULL) break;

    std::cout << buf;

    // remove ESC 
    std::string buf_no_esc = buf;
    while(size_t p = buf_no_esc.find_first_of("\033")){
      if (p==std::string::npos) break;
      buf_no_esc.replace(p, 1, "");
    }

    fprintf(sock_file, "%s", buf_no_esc.c_str());

    if (strncmp("Going to next", buf, 13)==0){
      std::cout << "------------------------------\n";
      fprintf(sock_file, "\x04");

      fflush(sock_file);
      fclose(sock_file);
      sock_file = accept_connection(sock);
      http_header(sock_file);
    }
  } while(1==1);
}
