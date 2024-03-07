#!/bin/bash

# Define a function to run the script in the background
run_script() {
    ./test/integration/run-load.sh -p 0 &
    # Store the PID of the background process
    child_pids+=($!)
}

# Trap SIGINT (Ctrl+C) signal to stop all child processes
trap 'kill ${child_pids[@]}' SIGINT

# Array to store child process PIDs
declare -a child_pids

# Run the script 20 times in parallel
for ((i=0; i<20; i++)); do
    run_script
done

# Wait for all child processes to finish
wait

echo "All child processes stopped."
