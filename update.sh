#!/bin/bash

if sudo pacman -Syu; then
    notify-send 'The system has been updated!'
else
    notify-send 'The update has failed!'
fi
pkill -RTMIN+8 waybar
