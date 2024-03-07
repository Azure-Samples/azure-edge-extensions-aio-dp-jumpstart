#!/bin/bash

MQ_OUTPUT_TOPIC=$1
WORKSPACE=".workspace"
OUTPUT_FOLDER="$WORKSPACE/$MQ_OUTPUT_TOPIC"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

mkdir -p $OUTPUT_FOLDER

CMD_SUB_CUSTOM="$PWD/_sub_custom.sh"

# Subscribe to the MQTT output topic
if [ -e "$CMD_SUB_CUSTOM" ]; then
  CMD_SUB="$CMD_SUB_CUSTOM '$MQ_OUTPUT_TOPIC'"
else
  CMD_SUB="$SCRIPT_DIR/_sub.sh '$MQ_OUTPUT_TOPIC'"
fi

#kubectl exec --stdin mqtt-client -n azure-iot-operations -- mosquitto_sub \
#      -q 1 -V mqttv5 -h aio-mq-dmqtt-frontend -p 8883\
#      -t $MQ_OUTPUT_TOPIC \
#      -u '$sat' -P "$(cat $MQ_CREDENTIALS_FILE)" --insecure --cafile /var/run/certs/ca.crt |
eval $CMD_SUB |
while read -r message
do
  echo "$message" | jq
  # Generate a unique identifier (UUID) for the output file
  timestamp=$(date -d "today" +"%Y%m%d%H%M%S%3N")
  output_file="$OUTPUT_FOLDER/$timestamp.json"

  # Save the received message to the output folder with a unique identifier
  echo "$message" > "$output_file"
  echo "Message saved to $output_file"
done