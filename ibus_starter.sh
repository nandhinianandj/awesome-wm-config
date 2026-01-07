#!/bin/sh
run() {
  if ! pgrep -f "$1"; then
    "$@" &
  fi
}
# Start the ibus daemon with the necessary flags
run "ibus-daemon" "-drx" &

