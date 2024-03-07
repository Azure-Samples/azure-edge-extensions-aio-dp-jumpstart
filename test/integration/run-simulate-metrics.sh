#!/bin/bash

trap "trap - SIGTERM && kill -- -$$ 2>/dev/null" SIGINT SIGTERM EXIT

lines=(
    "zurich/line-1/1234"
    "zurich/line-2/1235"
    "zurich/line-3/001"
    "mexico/line-1/1234"
    "mexico/line-2/002"
    "brazil/line-1/001"
    "ukraine/line-1/001"
    "philippines/line-1/001"
    "mongolia/line-1/001"
)

# Iterate over each command and run them in the background
for line in "${lines[@]}"; do
    ./simulate-metrics.sh "$line" &
    sleep 1
done

read -p "Press any key to finish ..." </dev/tty
