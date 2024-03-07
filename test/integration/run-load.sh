#!/bin/bash

#!/bin/bash

# Default values
MACHINES=10
SITES=50
PERIOD=1
MQ_INPUT_TOPIC="zurich/opcua"

# Function to display usage information
usage() {
    echo "Usage: $0 [-m <machines>] [-s <sites>] [-p <period>] [-t <topic>]" 1>&2
    exit 1
}

# Parse command-line options
while getopts ":m:s:p:t:" opt; do
    case ${opt} in
        m )
            MACHINES=$OPTARG
            ;;
        s )
            SITES=$OPTARG
            ;;
        p )
            PERIOD=$OPTARG
            ;;
        t )
            MQ_INPUT_TOPIC=$OPTARG
            ;;
        \? )
            echo "Invalid option: $OPTARG" 1>&2
            usage
            ;;
        : )
            echo "Option -$OPTARG requires an argument." 1>&2
            usage
            ;;
    esac
done
shift $((OPTIND -1))

# Displaying final settings
echo "- MACHINES: $MACHINES"
echo "- SITES: $SITES"
echo "- PERIOD: $PERIOD"
echo "- MQ_INPUT_TOPIC: $MQ_INPUT_TOPIC"

sequence=0

for SITE_NUMBER in $(seq 1 $SITES); do
    total=$((total + 1))
    for MACHINE_NUMBER in $(seq 1 $MACHINES); do
        sleep $PERIOD
        
        sequence=$((sequence + 1))
        TIMESTAMP=`date -u +"%Y-%m-%dT%H:%M:%S.%NZ"`
        CUSTOM_JSON="[
            {
                \"Timestamp\": \"2023-12-18T07:08:51.9706158Z\",
                \"MessageType\": \"ua-deltaframe\",
                \"Payload\": {
                    \"ns=$SITE_NUMBER;s=$MACHINE_NUMBER.Status.Mode1\": {
                        \"SourceTimestamp\": \"$TIMESTAMP\",
                        \"Value\": true
                    },
                    \"ns=$SITE_NUMBER;s=$MACHINE_NUMBER.Counter.GoodCounter\": {
                        \"SourceTimestamp\": \"$TIMESTAMP\",
                        \"Value\": $total
                    }
                },
                \"DataSetWriterName\": \"SomeName\",
                \"SequenceNumber\": $sequence
            }]"

        PAYLOAD=$(echo "$CUSTOM_JSON" | jq -c .)

        echo $PAYLOAD | jq

        mosquitto_pub -m "$PAYLOAD" -t $MQ_INPUT_TOPIC -i test
    done
done
