#!/bin/sh

# Quickshell 0.3.x can remain alive but unusable after the lock screen or
# DPMS removes/re-adds an output.  Always start a clean instance on resume.
pkill -TERM -x qs 2>/dev/null || true

# Do not race the old process when it is still shutting down.
i=0
while pgrep -x qs >/dev/null 2>&1 && [ "$i" -lt 20 ]; do
    sleep 0.1
    i=$((i + 1))
done

if pgrep -x qs >/dev/null 2>&1; then
    pkill -KILL -x qs 2>/dev/null || true
fi

sleep 0.2
nohup qs >>"${XDG_RUNTIME_DIR:-/tmp}/quickshell.log" 2>&1 </dev/null &
