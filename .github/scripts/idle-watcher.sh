#!/bin/bash

# Default timeout 600s
TIMEOUT=${IDLE_TIMEOUT:-600}

if [ "$TIMEOUT" -le 0 ]; then
    echo "Idle timeout is set to $TIMEOUT. Idle watcher is disabled."
    exit 0
fi

CHECK_INTERVAL=30
IDLE_TIME=0

echo "Starting idle watcher with timeout: ${TIMEOUT}s"

while true; do
    # Get local info to filter out
    MY_TS_IP=$(tailscale ip -4 || echo "___none___")
    MY_HOSTNAME=$(hostname)

    # 1. Check traditional login sessions (SSH, etc.)
    SESSION_WHO_RAW=$(who)
    SESSION_WHO=$(echo "$SESSION_WHO_RAW" | grep -q . && echo "yes" || echo "no")
    
    # 2. Check for active Tailscale sessions (excluding local node)
    # We filter out our own IP and Hostname
    SESSION_TS_RAW=$(tailscale status --active | grep -v "$MY_TS_IP" | grep -v "$MY_HOSTNAME" | grep -v "127.0.0.1" | grep -v "^$" || true)
    SESSION_TS=$(echo "$SESSION_TS_RAW" | grep -q . && echo "yes" || echo "no")
    
    # 3. Check for other established TCP connections
    # We exclude tailscaled's background management traffic to ports 80/443/53
    SESSION_SS_RAW=$(ss -tnp | grep "ESTAB" | grep -v ":80 " | grep -v ":443 " | grep -v ":53 " || true)
    # Further filter: if it's tailscaled, it must not be the management IPs we saw
    SESSION_SS=$(echo "$SESSION_SS_RAW" | grep -q . && echo "yes" || echo "no")

    if [ "$SESSION_WHO" = "yes" ] || [ "$SESSION_TS" = "yes" ] || [ "$SESSION_SS" = "yes" ]; then
        # Active sessions found
        if [ $IDLE_TIME -ne 0 ]; then
            echo "$(date): Activity detected. Resetting idle timer."
        fi
        IDLE_TIME=0
    else
        # No sessions found
        IDLE_TIME=$((IDLE_TIME + CHECK_INTERVAL))
        if [ $((IDLE_TIME % 60)) -eq 0 ] || [ $IDLE_TIME -ge $TIMEOUT ]; then
            echo "$(date): No active sessions. Idle for ${IDLE_TIME}s (Timeout: ${TIMEOUT}s)."
        fi
        
        if [ $IDLE_TIME -ge $TIMEOUT ]; then
            echo "$(date): Idle timeout reached. Triggering shutdown."
            /usr/local/bin/action-shutdown
            break
        fi
    fi
    sleep $CHECK_INTERVAL
done
