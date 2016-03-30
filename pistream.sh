#! /bin/sh
### BEGIN INIT INFO
# Provides:             pistream
# Required-Start:       $all
# Required-Stop:        $local_fs
# Default-Start:        3
# Default-Stop:         0 6
# Short-Description:    Stream video
# Description:          Control video streaming from raspberry pi
### END INIT INFO

# streaming target info

PROTO=rtmp
HOST=a.rtmp.youtube.com
YTKEY=`cat /usr/local/etc/pistream/ytkey.key`
URL=$PROTO://$HOST/live2/$YTKEY

# streaming quality settings
HEIGHT=360
WIDTH=640
BITRATE=300000
KEYFRAMES=50
FPS=25

# streaming target host resolution

MAX_TRIES=10
WAIT_TIME=10s

# variables, logs

NAME=pistream
LVAR=/var/local/pistream
ERR=$LVAR/pistream-error.log
LOG=$LVAR/pistream.log
PID=$LVAR/pistream.pid

# user info
PISTREAM_USER=pi

d_start() {
        echo "Checking if pistream is already running..."

        if [ -f $PID ]; then
                PID_VALUE=`cat $PID`
                if [ ! -z "$PID_VALUE" ]; then
                PID_VALUE=`ps ax | grep $PID_VALUE | grep -v grep | awk '{print $1}'`
                        if [ ! -z "$PID_VALUE" ]; then
                                echo "pistream is already running under pid:$PID_VALUE"

                                exit 1;
                        fi
                fi
        fi

        echo "Attmpting to resolve $HOST..."

        TRIES=1
        ping -c 1 $HOST > /dev/null
        TRY_RESULT="$?"

        while [ $TRY_RESULT -ne 0 -a $TRIES -lt $MAX_TRIES ]; do
                echo "Failed to resolve $HOST, trying again in $WAIT_TIME..."
                sleep $WAIT_TIME
                ping -c 1 $HOST > /dev/null
                TRY_RESULT="$?"
                TRIES=$(($TRIES+1))
        done

        if [ $TRY_RESULT -ne 0  ]; then
                echo "Failed to resolve $HOST after $TRIES attempt(s)..."
                exit 1;
        fi

        echo "Successfully resolved $HOST after $TRIES attempt(s)..."
        echo "Attempting to start streaming over $PROTO protocol..."

        # open the stream

        exec su PISTREAM_USER -l -c "nohup raspivid -o - -t 0 -w $WIDTH -h $HEIGHT -fps $FPS -g $KEYFRAMES -b $BITRATE | ffmpeg -re -ar 44100 -ac 2 -acodec pcm_s16le -f s16le -ac 2 -i /dev/zero -f h264 -i - -vcodec copy -acodec aac -ab 128k -r $FPS -g $KEYFRAMES -strict experimental -f flv $URL & echo \$! > $PID"
}

d_stop() {
            if [ -f $PID ]; then
                PID_VALUE=`cat $PID`
                if [ ! -z "$PID_VALUE" ]; then
                        PID_VALUE=`ps ax | grep $PID_VALUE | grep -v grep | awk '{print $1}'`
                        if [ ! -z "$PID_VALUE" ]; then
                                kill $PID_VALUE
                                WAIT_TIME=0
                                while [ `ps ax | grep $PID_VALUE | grep -v grep | wc -l` -ne 0 -a "$WAIT_TIME" -lt 2 ]
                                do
                                        sleep 1
                                        WAIT_TIME=$(expr $WAIT_TIME + 1)
                                done
                                if [ `ps ax | grep $PID_VALUE | grep -v grep | wc -l` -ne 0 ]; then
                                        WAIT_TIME=0
                                        while [ `ps ax | grep $PID_VALUE | grep -v grep | wc -l` -ne 0 -a "$WAIT_TIME" -lt 15 ]
                                        do
                                                sleep 1
                                                WAIT_TIME=$(expr $WAIT_TIME + 1)
                                        done
                                        echo
                                fi
                                if [ `ps ax | grep $PID_VALUE | grep -v grep | wc -l` -ne 0 ]; then
                                        kill -9 $PID_VALUE
                                fi
                        fi
                fi
                rm -f $PID
        fi
}

case "$1" in
        start)
                echo "Starting $NAME..."
                d_start
                ;;
        stop)
                echo "Stopping $NAME..."
                d_stop
                ;;
        restart|force-reload)
                echo "Restarting $NAME..."
                d_stop
                d_start
                ;;
        *)
                echo "Usage: sudo service $NAME {start|stop|restart}" >&2
                exit 1
                ;;
esac

exit 0