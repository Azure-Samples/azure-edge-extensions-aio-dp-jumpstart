#!/bin/bash

. ./validations/compare-values.sh

get_total_count() {
    local folder="$1"

    # Check if the folder exists
    if [ -d "$folder" ]; then

        # check for the latest file in the folder
        latest_file=$(ls -t "$folder" | head -n1)

        # put the value of .Value in a variable
        actual_count=$(jq -r '.Value' "$folder/$latest_file")

        # Output the actual count
        echo "$actual_count"
    fi
}

start_shift_total_counter() {
    local machine_name="$1"

    if [ -n "$machine_name" ]; then
        machine_name="-$machine_name"
    fi

    local folder="./assets/zurich-validation/start-shift-total-count/"
    local good_counter_file="${folder}start-shift-good-counter${machine_name}.json"
    local bad_counter_file="${folder}start-shift-bad-counter${machine_name}.json"

    cp "$good_counter_file" "$WORKSPACE/$INPUT_TOPIC"
    echo "Processing $good_counter_file"

    # Longer sleep so zeroes can process
    sleep 10

    cp "$bad_counter_file" "$WORKSPACE/$INPUT_TOPIC"
    echo "Processing $bad_counter_file"

    # Longer sleep so zeroes can process
    sleep 10
}

add_1_to_total_count() {
    local machine_name="$1"

    if [ -n "$machine_name" ]; then
        machine_name="-$machine_name"
    fi

    local folder="./assets/zurich-validation/total-counter/total-count-1/"
    local good_count_1_file="${folder}good-counter-1${machine_name}.json"

    # Extract the filename without the path
    filename=$(basename "$good_count_1_file")

    cp "$good_count_1_file" "$WORKSPACE/$INPUT_TOPIC"
    echo "Processing $good_count_1_file"
    sleep 1
}


test_for_total_counter() {
    local aio_topic="$WORKSPACE/$1/total-count"

    for folder in ./assets/zurich-validation/total-counter/*; do
        if [ -d "$folder" ]; then

            foldername=$(basename "$folder")

            # skip if folder is total-count-1
            if [ "$foldername" == "total-count-1" ]; then
                continue
            fi

            machine_name=''
            # Set count to be added and machine_name
            if [ "$foldername" == "total-count-250-multiple-shifts" ]; then 
                count_to_be_added=250;
            # Special case to test multiple machines scenario
            # Expected result: check that count_to_be_added sets to 150 for Machine2, although we send BadCounter=100 for Machine1
            elif [ "$foldername" == "total-count-150-machine2" ]; then 
                count_to_be_added=150
                machine_name="machine2";
            # Add additional scenario here: elif [ "$foldername" == "total-count-x" ]; then count_to_be_added=x;
            # Note: if you use a different machine name add: machine_name="your-machine-name"
            fi

            # Zero out good counter and bad counter
            start_shift_total_counter $machine_name

            # Add 1 to total count to retrieve the latest total count
            add_1_to_total_count $machine_name
            
            # Get current total count
            aio_current_count=$(get_total_count $aio_topic)
            blue "Current AIO count: $aio_current_count (from: $aio_topic)"

            aio_expected_count=$((count_to_be_added + aio_current_count))
            
            start_shift_total_counter $machine_name

            # Add to total count
            for file in "$folder"/*.json; do
                if [ -f "$file" ]; then
                    # Extract the filename without the path
                    filename=$(basename "$file")

                    cp "$file" "$WORKSPACE/$INPUT_TOPIC"
                    echo "Processing $file"

                    # Check if the filename contains "start-shift"
                    if [[ $filename == *"start-shift"* ]]; then
                        # If it does, sleep for 10 seconds
                        sleep 10
                    else
                        sleep 1
                    fi
                fi
            done

            # run the validation of the total count
            compare_values $aio_topic $aio_expected_count
        fi
    done
}