#! /bin/bash
#xmodmap -e "pointer = 3 2 1"
nohup dropbox start &
nohup nm-applet &
nohup rescuetime &
#synclient TouchpadOff=1


