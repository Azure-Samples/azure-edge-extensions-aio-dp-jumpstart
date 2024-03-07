#!/bin/bash

. ../utils/set-colors.sh

check_folder_validity() {
    local folder="$1"
    local count="$2"
    local min_sequence="$3"
    local max_sequence="$4"

    # Check if the folder exists
    if [ -d "$folder" ]; then
        # Count the number of files in the folder
        file_count=$(find "$folder" -maxdepth 1 -type f | wc -l)

        # Check if there are exactly 3 files
        if [ "$file_count" -eq $count ]; then
            green "INFO: $file_count messages found"   
        else
            red "ERROR: The folder $folder does not have exactly $count messages [$file_count found]."
        fi

        # if the folder name is in the metrics folder, we don't need to check the sequence number
        if [[ "$folder" == *metrics* ]]; then        
                # Use jq to check if the JSON is valid and has the required property
                if jq -e --argjson min "$min_sequence" --argjson max "$max_sequence" \
                    '.sequenceNumber | numbers | select(. >= $min and . <= $max)' "$file" >/dev/null 2>&1; then
                    green "INFO: $file processed correctly."
                else
                    red "ERROR: $file processed incorrectly."
                fi
            return
        fi

        # Check each file for valid JSON with "sequenceNumber" in the specified range
        for file in "$folder"/*; do
            if [ -f "$file" ]; then
                # Use jq to check if the JSON is valid and has the required property
                if jq -e --argjson min "$min_sequence" --argjson max "$max_sequence" \
                    '.sequenceNumber | numbers | select(. >= $min and . <= $max)' "$file" >/dev/null 2>&1; then
                    green "INFO: $file processed correctly."
                else
                    red "ERROR: $file processed incorrectly."
                fi
            fi
        done
    else
        red "ERROR: The folder $folder does not exist."
        exit 1
    fi
}

test_for_valid_data() {
    valid_counter=0
    invalid_counter=0

    for folder in ./assets/zurich-validation/data-validation/*; do
        if [ -d "$folder" ]; then

            foldername=$(basename "$folder")

            for file in "$folder"/*.json; do
                if [ -f "$file" ]; then
                    # Extract the filename without the path
                    filename=$(basename "$file")

                    cp "$file" "$WORKSPACE/$INPUT_TOPIC/"
                    echo "Processing $file"

                    # Check if the file starts with "valid" or "invalid"
                    if [[ "$filename" == valid* ]]; then
                        ((valid_counter++))
                    elif [[ "$filename" == invalid* ]]; then
                        ((invalid_counter++))
                    fi

                    # Giving some chance of process files sequencially
                    # sleep 3
                fi
            done
        fi
    done

    blue "=> [EXPECTED] Valid: $valid_counter, Invalid: $invalid_counter"

    total_files=$((valid_counter + invalid_counter))

    blue "=> Waiting for processing [$total_files seconds] ..."

    sleep $total_files

    echo ""
    blue "=> [TEST RESULTS]"
    echo ""

    # By convention all the valid messages start with valid- and contains a sequenceNumber between 9000-9999
    check_folder_validity "$WORKSPACE/$INPUT_TOPIC/valid" $valid_counter 9000 9999

    # By convention all the invalid messages start with invalid- and contains a sequenceNumber between 8000-8999
    check_folder_validity "$WORKSPACE/$INPUT_TOPIC/invalid" $invalid_counter 8000 8999
} 
