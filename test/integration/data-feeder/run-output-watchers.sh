#!/bin/bash

run_output_watchers() {
    for topic in "${!topics_and_logs[@]}"; do
        blue "=> Running output watcher on $topic"
        ./data-feeder/run-output.sh "$topic" > "$WORKSPACE/logs/${topics_and_logs[$topic]}" &
    done

    # Waiting a little bit to ensure output watcher is listening ...
    sleep 2
}
