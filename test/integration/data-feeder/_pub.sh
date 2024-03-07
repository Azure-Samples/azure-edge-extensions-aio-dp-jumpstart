#!/bin/bash

set -e 

MQ_INPUT_TOPIC=$1
PAYLOAD=$2

MQ_CREDENTIALS_FILE=".mq-sat"

echo $PAYLOAD

# Connects to mqtt-client which contains credentials and certificates

# kubectl exec --stdin mqtt-client -n azure-iot-operations -- mosquitto_pub \
#   -q 1 -V mqttv5 -d -h aio-mq-dmqtt-frontend -p 8883\
#   -m "$PAYLOAD" -t $MQ_INPUT_TOPIC -i test \
#   -u '$sat' -P "$(cat $MQ_CREDENTIALS_FILE)" --insecure --cafile /var/run/certs/ca.crt

# If your cluster has redirected the ports to localhost, replace the previous command for
mosquitto_pub -m "$PAYLOAD" -t $MQ_INPUT_TOPIC -i test
