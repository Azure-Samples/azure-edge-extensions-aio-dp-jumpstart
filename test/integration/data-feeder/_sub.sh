#!/bin/bash

set -e 

MQ_OUTPUT_TOPIC=$1

# Connects to mqtt-client which contains credentials and certificates

#MQ_CREDENTIALS_FILE=".mq-sat"

#if [ ! -e "$MQ_CREDENTIALS_FILE" ]; then
#  echo "Trying to obtain mq-sat credentials ..."
#  kubectl cp mqtt-client:/var/run/secrets/tokens/..data/mq-sat $MQ_CREDENTIALS_FILE -n azure-iot-operations
#fi


#kubectl exec --stdin mqtt-client -n azure-iot-operations -- mosquitto_sub \
#      -q 1 -V mqttv5 -h aio-mq-dmqtt-frontend -p 8883 \
#      -t $MQ_OUTPUT_TOPIC \
#      -u '$sat' -P "$(cat $MQ_CREDENTIALS_FILE)" --insecure --cafile /var/run/certs/ca.crt

# If your cluster has redirected the ports to localhost, replace the previous command for
mosquitto_sub -t $MQ_OUTPUT_TOPIC &