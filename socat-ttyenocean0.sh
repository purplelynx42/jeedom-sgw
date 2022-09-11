#!/bin/bash
###
### socat loader for serial over ip purpose
###

# Settings
TTY='ttyEnOcean0'
HOST='10.10.3.12'
PORT='8888'
MAXRETRY=3
HOLDTIMER=15

# Daemon Loop
startcounter=0
startattempt=0
((throttleattempt=MAXRETRY))
timestamp=$(date +%s)
#timestamp=`date '+%Y-%m-%d %H:%M:%S'`
rcsocat=0
echo "${timestamp} socat loader $TTY : begin of the start loop"
while :
  do
    ping -c 1 $HOST > /dev/null;
    rcping=$?
    if [ $rcping -eq 0 ];
      then
	echo "${timestamp} socat loader $TTY : serial server $HOST seems to be up."
        if [ $throttleattempt -gt 0 ];
          then
            ((startattempt++))
	    echo "${timestamp} socat loader $TTY : attempt $startattempt to start socat ($startcounter successful start - throttling in $throttleattempt attempt)"
            socat -d -d -lf /var/log/socat-$TTY.log pty,link=/dev/$TTY,raw,ignoreeof,echo=0,user=root,group=dialout,mode=660 tcp:$HOST:$PORT,keepalive,keepcnt=3,keepidle=3,keepintvl=1
            rcsocat=$?
            echo "${timestamp} socat loader $TTY : socat is exiting with code $rcsocat"
            case $rcsocat in
              0)
                ((startcounter++))
		            ((throttleattempt=MAXRETRY))
                ;;
              1)
                ((throttleattempt=0))
                ;;
	            137)
            		((startcounter++))
            		((throttleattempt--))
	              ;;
              *)
                ((throttleattempt--))
                ;;
            esac
          else
            echo "${timestamp} socat loader $TTY : serial server $HOST seems BUSY ! : Throttling for 15 seconds..."
            sleep $HOLDTIMER
 	          ((throttleattempt=MAXRETRY))
        fi
      else
        echo "${timestamp} socat loader $TTY : serial server $HOST seems DOWN ! : Retry in 15 seconds..."
        sleep $HOLDTIMER
    fi
  done