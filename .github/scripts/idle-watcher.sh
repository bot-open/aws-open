#!/bin/bash

TIMEOUT=${IDLE_TIMEOUT:-120}
CHECK_INTERVAL=30
IDLE_TIME=0

sleep $CHECK_INTERVAL

while sleep $CHECK_INTERVAL; do
    if pgrep -x login > /dev/null \
    || pgrep -x mosh-server > /dev/null \
    || pgrep -fx tmux > /dev/null; then
        IDLE_TIME=0
    else
        IDLE_TIME=$((IDLE_TIME + CHECK_INTERVAL))
        if [ $IDLE_TIME -ge $TIMEOUT ]; then
            /usr/local/bin/action-shutdown
            break
        fi
    fi
done
