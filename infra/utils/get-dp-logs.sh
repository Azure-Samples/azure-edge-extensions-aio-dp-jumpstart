#!/bin/bash

while getopts ":p:s:e:c:" opt; do
  case ${opt} in
    p )
      PIPELINE_ID=$OPTARG
      ;;
    s )
      STAGE_ID=$OPTARG
      ;;
    e )
      EVENT_TYPE=$OPTARG
      ;;
    c )
      CUSTOM=$OPTARG
      ;;
    \? )
      echo "Usage: $0 [-p pipeline_id] [-s stage_id] [-e event_type] [-c custom]" 1>&2
      exit 1
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))


# Check if none of the options are provided
if [ -z "$PIPELINE_ID" ] && [ -z "$STAGE_ID" ] && [ -z "$EVENT_TYPE" ] && [ -z "$CUSTOM" ]; then
  echo "Usage: $0 [-p pipeline_id] [-s stage_id] [-e event_type] [-c custom]" 1>&2
  exit 1
fi

# Get all the pods inside the azure-iot-operations namespace
pods=$(kubectl get pods -n azure-iot-operations | grep "^aio-dp" | awk '{print $1}')

# Iterate through each pod and get the logs filtering for the pipeline provided, returns last 10
for pod in $pods; do
    logs=$(kubectl logs $pod -n azure-iot-operations 2>/dev/null)

    # Conditionally filter logs based on provided variables
    if [ -n "$PIPELINE_ID" ]; then
        logs=$(echo "$logs" | grep -F "\"pipeline.id\":\"$PIPELINE_ID\"")
    fi

    if [ -n "$STAGE_ID" ]; then
        logs=$(echo "$logs" | grep -F "\"stage.id\":\"$STAGE_ID\"")
    fi

    if [ -n "$EVENT_TYPE" ]; then
        logs=$(echo "$logs" | grep -F "\"name\":\"$EVENT_TYPE\"")
    fi

    if [ -n "$CUSTOM" ]; then
        logs=$(echo "$logs" | grep -F "$CUSTOM")
    fi

    echo "$logs" | tail -n 20 | jq
done
