#!/bin/bash

min_seconds="${1:-1}"
max_seconds="${2:-3600}"
seconds="$(shuf -i "${min_seconds}"-"${max_seconds}" -n 1)"

# current time - seconds
start=$(date -d "@$(($(date +%s) + $seconds))")
echo "Will sleep for $seconds seconds. Backup will start at approximately $start"

sleep $seconds

echo "Done sleeping"
