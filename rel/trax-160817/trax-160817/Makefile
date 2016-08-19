all:	trax-host trax-httpd trax-player

CFLAGS   =  -Wall -Wextra
CXXFLAGS =  -Wall -Wextra -Wpedantic

COMMON_SRCS = trax.cc move.cc trace.cc validation.cc

TRAX_SRCS = trax-host.cc $(COMMON_SRCS)
TRAX_OBJS = $(TRAX_SRCS:%.cc=%.o)

PLAYER_SRCS = trax-player.cc $(COMMON_SRCS)
PLAYER_OBJS = $(PLAYER_SRCS:%.cc=%.o)



PKG = trax-`date "+%y%m%d"`

.SUFFIXES: .cc

.cc.o:
	$(CXX) $(CXXFLAGS) -c $<

trax-httpd: trax-httpd.cc
	$(CXX) $(CXXFLAGS) -o trax-httpd $(LDFLAGS) trax-httpd.cc

trax-host: $(TRAX_OBJS)
	$(CXX) $(CXXFLAGS) -o trax-host $(TRAX_OBJS) $(LDFLAGS)

trax-player: $(PLAYER_OBJS)
	$(CXX) $(CXXFLAGS) -o trax-player $(PLAYER_OBJS) $(LDFLAGS)

package:
	-rm -rf $(PKG); svn export http://lut.eee.u-ryukyu.ac.jp/traxjp/svn/trunk $(PKG); zip -r $(PKG).zip $(PKG)

clean:
	-rm -rf *.o *~ core trax-host trax-player trax-comm trax-httpd
