#!/bin/bash

# Default timeout 120s
TIMEOUT=${IDLE_TIMEOUT:-120}

if [ "$TIMEOUT" -le 0 ]; then
    echo "Idle timeout is set to $TIMEOUT. Idle watcher is disabled."
    exit 0
fi

CHECK_INTERVAL=30
IDLE_TIME=0

echo "Starting idle watcher with timeout: ${TIMEOUT}s (Process tree method)"

while true; do
    SESSION_ACTIVE=0

    # Get the PID of tailscaled
    TS_PID=$(pgrep -x tailscaled | head -n 1)

    if [ -n "$TS_PID" ]; then
        # Check for child processes (SSH sessions, SFTP, port forwarding, etc.)
        CHILD_PROCESSES=$(ps --ppid "$TS_PID" --no-headers 2>/dev/null)

        if [ -n "$CHILD_PROCESSES" ]; then
            SESSION_ACTIVE=1
        fi
    fi

    if [ "$SESSION_ACTIVE" -eq 1 ]; then
        # Activity detected, reset timer
        # echo "$(date): Activity detected. Resetting timer."
        IDLE_TIME=0
    else
        # No activity, increment timer
        IDLE_TIME=$((IDLE_TIME + CHECK_INTERVAL))

        # Periodic idle status logging (Commented out to reduce noise)
        # if [ $((IDLE_TIME % 60)) -eq 0 ] || [ $IDLE_TIME -ge $TIMEOUT ]; then
        #     echo "$(date): Idle for ${IDLE_TIME}s (Timeout: ${TIMEOUT}s)."
        # fi

        # Trigger shutdown on timeout
        if [ $IDLE_TIME -ge "$TIMEOUT" ]; then
            echo "$(date): Idle timeout reached. Triggering shutdown."
            /usr/local/bin/action-shutdown
            break
        fi
    fi

    sleep $CHECK_INTERVAL
done