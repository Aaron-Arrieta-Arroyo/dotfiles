#!/bin/bash

MARKER="/tmp/caelestia-game-mode"

if [ -f "$MARKER" ]; then
    hyprctl keyword animations:enabled true
    hyprctl keyword decoration:blur:enabled true
    hyprctl keyword decoration:shadow:enabled true
    rm "$MARKER"
    notify-send "Game Mode" "Off — rendimiento normal restaurado"
else
    hyprctl keyword animations:enabled false
    hyprctl keyword decoration:blur:enabled false
    hyprctl keyword decoration:shadow:enabled false
    touch "$MARKER"
    notify-send "Game Mode" "On — blur, sombras y animaciones desactivados"
fi
