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
    # 1. Check traditional login sessions
    SESSION_WHO=$(who | grep -q . && echo "yes" || echo "no")
    
    # 2. Check for active Tailscale SSH sessions via ss (Tailscale SSH uses port 2222 by default internally)
    SESSION_SS=$(ss -tnp | grep -q "tailscaled" && echo "yes" || echo "no")
    
    # 3. Check tailscale status for active sessions
    SESSION_TS=$(tailscale status --active | grep -q . && echo "yes" || echo "no")

    if [ "$SESSION_WHO" = "yes" ] || [ "$SESSION_SS" = "yes" ] || [ "$SESSION_TS" = "yes" ]; then
        # Active sessions found
        if [ $IDLE_TIME -ne 0 ]; then
            echo "$(date): Session active (who:$SESSION_WHO, ss:$SESSION_SS, ts:$SESSION_TS). Resetting idle timer."
            IDLE_TIME=0
        fi
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
