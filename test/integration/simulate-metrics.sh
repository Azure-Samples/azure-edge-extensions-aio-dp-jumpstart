#!/bin/bash
total=15
count=0
machine_status=3
limit=5
context=$1
metrics_topic=$2

IFS='/' read -r plant_id line_id machine_id <<< "$context"

while true; do
    if [ "$machine_status" -eq 0 ]; then
        increment_total=0
    elif [ "$machine_status" -eq 3 ]; then
        increment_total=0
    else
        increment_total=$(shuf -i 1-5 -n 1)
    fi
    total=$((total + increment_total))

    count=$((count+1))

    # We do not update machine status in each run, but randomly
    if [ $((count % limit)) -eq 0 ]; then
        echo "Updating machine status"
        count=1
        limit=$(shuf -i 9-20 -n 1)

        random_num=$(( (RANDOM % 100) + 1 ))
        
        # Determine machine status based on probabilities
        if [ "$random_num" -lt "40" ]; then
            machine_status=1
        elif [ "$random_num" -lt "70" ]; then
            machine_status=2
        elif [ "$random_num" -lt "80" ]; then
            machine_status=0
        elif [ "$random_num" -lt "95" ]; then
            machine_status=3
        else
            machine_status=99
        fi
    fi
    
    ./data-feeder/_pub.sh "metrics/aio/total-count" "{ \"PlantId\": \"$plant_id\", \"MachineId\": \"$machine_id\", \"LineId\": \"$line_id\", \"VariableId\": \"TOTAL_COUNT\", \"Value\": $total }";
    sleep 1
    ./data-feeder/_pub.sh "metrics/aio/machine-status" "{ \"PlantId\": \"$plant_id\", \"MachineId\": \"$machine_id\", \"LineId\": \"$line_id\", \"VariableId\": \"MACHINE_STATUS\", \"Value\": $machine_status }";
done
