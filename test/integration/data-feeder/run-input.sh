#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
WORKSPACE=".workspace"

MQ_INPUT_TOPIC=$1

INPUT_FOLDER="$WORKSPACE/$MQ_INPUT_TOPIC"
PROCESSED_FOLDER="$WORKSPACE/$MQ_INPUT_TOPIC-processed"

mkdir -p "$INPUT_FOLDER"
mkdir -p "$PROCESSED_FOLDER"

echo "Listening to $PWD/$INPUT_FOLDER ..."

CMD_PUB_CUSTOM="$PWD/_pub_custom.sh"

# Start inotifywait to monitor input folder for new .json files
inotifywait -m -e create -e moved_to --format "%w%f" "$INPUT_FOLDER" |
while read -r file
do
  if [[ $file == *.json ]]; then
    # Publish the file to the MQTT input topic
    PAYLOAD=$(cat $file | tr -d '\n' | tr -d '\r')
    ESCAPED_PAYLOAD=$(printf "%q" "$PAYLOAD")

    echo $PAYLOAD
    
    if [ -e "$CMD_PUB_CUSTOM" ]; then
      CMD_PUB="$CMD_PUB_CUSTOM '$MQ_INPUT_TOPIC' '$PAYLOAD'"
      eval $CMD_PUB
    else
      CMD_PUB="$SCRIPT_DIR/_pub.sh '$MQ_INPUT_TOPIC' '$PAYLOAD'"
      eval $CMD_PUB
    fi

    # Check if mosquitto_pub was successful
    if [ $? -eq 0 ]; then
      echo "File successfully sent to MQTT broker. Moving to $PROCESSED_FOLDER"
      mv "$file" "$PROCESSED_FOLDER/"
    else
      echo "Error publishing file to MQTT. File not moved."
    fi
  fi
done