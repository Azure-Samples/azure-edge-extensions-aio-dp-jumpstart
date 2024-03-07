#!/bin/bash

. ./validations/compare-values.sh
. ../utils/set-colors.sh

test_for_machine_status() {
    local aio_topic="$WORKSPACE/$1/machine-status"

    for folder in ./assets/zurich-validation/machine-status/*; do
        if [ -d "$folder" ]; then

            foldername=$(basename "$folder")

            if [ "$foldername" == "fault" ]; then expected_status="FAULT";
            elif [ "$foldername" == "idle" ]; then expected_status="IDLE";
            elif [ "$foldername" == "mode1" ]; then expected_status="MODE1";
            elif [ "$foldername" == "mode2" ]; then expected_status="MODE2";
            # Special case to test multiple machines scenario
            # Expected result: check that expected_status for Machine2 is "IDLE", although we send payload Fault=true for Machine1
            elif [ "$foldername" == "multiple-machines" ]; then expected_status="IDLE";
            else expected_status="UNDEFINED";
            fi
            
            for file in "$folder"/*.json; do
                if [ -f "$file" ]; then
                    # Extract the filename without the path
                    filename=$(basename "$file")

                    cp "$file" "$WORKSPACE/$INPUT_TOPIC"
                    echo "Processing $file"

                    # Giving some chance of process files sequencially
                    sleep 1
                fi
            done

            # run the validation of the status
            compare_values $aio_topic $expected_status

        fi
    done
}
