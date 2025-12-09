#!/usr/bin/env bash
# Daemon priority script for Ambxst
# Terminates conflicting notification daemons and hypridle instances
# to prioritize the Ambxst/flake versions

# Kill notification daemons that may conflict
for daemon in dunst mako swaync; do
  if pgrep -x "$daemon" >/dev/null; then
    echo "Stopping $daemon..."
    pkill -x "$daemon"
  fi
done

# Kill existing hypridle instances (including system-wide)
if pgrep -x "hypridle" >/dev/null; then
  echo "Stopping existing hypridle instances..."
  pkill -x "hypridle"
  sleep 0.5
fi

# Start hypridle from flake (will be in PATH via the flake)
if command -v hypridle >/dev/null; then
  echo "Starting hypridle from Ambxst environment..."
  nohup hypridle >/dev/null 2>&1 &
else
  echo "Warning: hypridle not found in PATH"
fi
