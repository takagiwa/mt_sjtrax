#!/bin/bash

help_msg()
{
    echo "Usage: match.sh [-lr] Player1 Player2"
    echo " "
    echo "   -t (x): Set communication timeout to (x) seconds"
    echo "   -l    : Enable game log"
    echo "   -r    : Player 1 as black, Player 2 as white"
    echo "   -w    : Enable 'wait' mode on communication. Quick moves will appear slowly"
    echo "   -h    : Show this message"
    echo " "
    echo "   Player = 'path to executable file'  : executable trax client"
    echo "            'path to character device' : serial port device"
    echo "            'TCP port # (100xx)'       : TCP port"
    echo "            auto:                      : autoscan serial ports"
    echo "            bot:                       : 'trax-player' bot"
}

test_player()
{
    # test_player(command argument player1 or player2)
    
    if [ -x $1 ]; then
	echo executable   # uses TCP, socat
	return 1
    fi

    if [ -c $1 ]; then
	echo character device $1
	return 2
    fi

    if [[ $1 == 100[0-9][0-9] ]]; then
	echo TCP port $1    # uses TCP
	return 3
    fi

    if [[ $1 == auto ]]; then
	echo Serial autoscan
	return 4
    fi

    if [[ $1 == bot ]]; then
	echo Trax bot    # uses TCP, socat, trax_player
	return 5
    fi
    echo "Unknown player description: " $1
    exit -1
}

check_commands()
{
    if [ ! `which trax-host` ]; then
	echo trax-host is not in PATH!
	exit -1;
    fi

    if [[ $2 == 1 || $2 == 5 ]]; then
	if [ ! `which socat` ]; then
	    echo socat is required but not in PATH!
	    exit -1;
	fi
    fi

    if [[ $2 == 5 ]]; then
	if [ ! `which trax-player` ]; then
	    echo trax-player is required but not in PATH!
	    exit -1;
	fi
    fi
}

player_port_dev()
{
    # player_port_dev(player#, test_player() result, command argument)
    case "$2"
    in
	2|4)
	    echo $3
	    ;;
	3)
	    echo $3
	    ;;
	*)
	    echo 1010$1
	    ;;
    esac
}

launch_socat ()
{
    # launch_socat (player_type player_dev command_arg)
    if [[ $1 == 1 || $1 == 5 ]]; then
	bot_cmd=$3
	if [[ $3 == bot ]]; then
	    bot_cmd=trax-player
	fi
	
	cmd="socat TCP:localhost:${2},retry=100,interval=0.1 exec:\"${bot_cmd}\",pty,ctty,echo=0"
	echo $cmd
	$cmd &
    else
	# no socat
	return
    fi
}

# ----------------------------------------
# startup

waitmode=''
reverse=''
logging=''
timeout=''

player1=auto
player2=auto

args=`getopt wrlt:h $*`
set -- $args
for i; do
    case "$i"
    in
        -w)
            waitmode=' -w ';
            shift
            ;;
    	-r)	
    	    reverse=' -r ';
	    shift
	    ;;
	-l)			  
	    logging=' -l '
	    shift
	    ;;
	-t)
	    timeout=" -t $2 "
	    shift; shift
	    ;;
	-h)
	    help_msg
	    exit
    esac
done

if [ $# != 3 ] ; then
    help_msg
    exit
fi

# ----------------------------------------
# test player arguments

printf 'Player 1: '
test_player $2
player1_type=$?
player1=`player_port_dev 1 $player1_type $2`

printf 'Player 2: '
test_player $3
player2_type=$?
player2=`player_port_dev 2 $player2_type $3`

# ----------------------------------------
# make sure everything is available

check_commands $player1_type
check_commands $player2_type


launch_socat $player1_type $player1 $2
launch_socat $player2_type $player2 $3 

trax-host $timeout $waitmode $reverse $logging $player1 $player2 
wait
