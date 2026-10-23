#!/bin/bash

# 1. Find the first connected monitor (usually your laptop screen or main display)
PRIMARY_SCREEN=$(xrandr | grep " connected" | awk '{print $1}' | head -n 1)

# 2. Automatically configure all connected screens and turn off disconnected ones
xrandr --auto

# 3. Force the primary screen to be active (in case it got disabled)
if [ ! -z "$PRIMARY_SCREEN" ]; then
    xrandr --output "$PRIMARY_SCREEN" --primary --auto
fi

# 4. Tell AwesomeWM to refresh its screen objects and move windows back
awesome-client "awesome.restart()"

