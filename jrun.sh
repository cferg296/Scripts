#!/usr/bin/env bash

JAVA_PID=$$

(
    # Give Swing/AWT time to create its window
    for _ in {1..50}; do
        if hyprctl -i 0 clients | grep -q "pid: $JAVA_PID"; then

            WINDOW="pid:$JAVA_PID"

            hyprctl -i 0 dispatch "hl.dsp.window.float({
                action = \"set\",
                window = \"$WINDOW\"
            })"

            #hyprctl -i 0 dispatch "hl.dsp.window.resize({
             #   x = 1000,
              #  y = 700,
               # window = \"$WINDOW\"
            #})"

            hyprctl -i 0 dispatch "hl.dsp.window.center({
                window = \"$WINDOW\"
            })"

            exit 0
        fi

        sleep 0.1
    done
) &

exec /usr/bin/java "$@"
