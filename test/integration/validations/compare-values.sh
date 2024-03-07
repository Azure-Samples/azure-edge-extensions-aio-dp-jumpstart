#!/bin/bash

compare_values() {
    local topic="$1"
    local expected_value="$2"
    
    # Check if the folder exists
    if [ -d "$topic" ]; then

        # check for the latest file in the folder
        latest_file=$(ls -t "$topic" | head -n1)

        # Check if latest file exists and is non-empty
        if [[ ! -n "$latest_file" ]]; then
            red "FATAL: Latest file in [$topic] is empty."
            exit
        fi

        # put the value of .Value in a variable
        actual_value=$(jq -r '.Value' "$topic/$latest_file")

        # add actual_value to array for comparison
        declare -A compare_values
        compare_values+=(
            ["$topic"]=$actual_value
        )

        # Check if the status is the expected
        if [ "$expected_value" == "$actual_value" ]; then
            green "INFO: [$topic] $latest_file contains expected value of $expected_value."
        else
            red "ERROR: [$topic] $latest_file contains unexpected value of $actual_value. Expected: $expected_value."
        fi
    fi
}