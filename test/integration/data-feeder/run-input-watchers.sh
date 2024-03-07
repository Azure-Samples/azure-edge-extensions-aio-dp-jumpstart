#!/bin/bash

run_input_watcher() {
    blue "=> Running input watcher on $INPUT_TOPIC"
    ./data-feeder/run-input.sh "$1" > $WORKSPACE/logs/zurich-input.log &
    # Waiting a little bit to ensure input watcher is listening ...
    sleep 2
}
