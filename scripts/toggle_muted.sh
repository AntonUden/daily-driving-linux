#!/bin/bash
PREV_WIN=$(kdotool getactivewindow)
VESKTOP_WIN=$(kdotool search --name "Discord" | head -n 1)
if [ -z "$VESKTOP_WIN" ]; then
    echo "Vesktop window not found!"
    exit 1
fi
kdotool windowactivate $VESKTOP_WIN
sleep 0.2
xdotool key --clearmodifiers ctrl+shift+m
sleep 0.1
if [ -n "$PREV_WIN" ]; then
    kdotool windowactivate $PREV_WIN
fi
