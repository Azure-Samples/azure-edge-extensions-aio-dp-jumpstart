#!/bin/bash

. ../utils/set-colors.sh
. ../utils/create-workspace.sh
. ./data-feeder/run-input-watchers.sh
. ./data-feeder/run-output-watchers.sh
. ./validations/validate-data.sh
. ./validations/validate-machine-status.sh
. ./validations/validate-total-counter.sh

declare -A topics_and_logs
topics_and_logs=(
  ["zurich/input/valid"]="zurich-valid.log"
  ["zurich/input/invalid"]="zurich-invalid.log"
  ["zurich/debug"]="zurich-debug.log"
  ["metrics/aio/machine-status"]="zurich-aio-machine-status.log"
  ["metrics/aio/total-count"]="zurich-aio-total-count.log"
)

WORKSPACE=".workspace"
INPUT_TOPIC="zurich/input"
AIO_METRICS_TOPIC="metrics/aio"

create_workspace $WORKSPACE
run_input_watcher $INPUT_TOPIC
run_output_watchers
test_for_valid_data
test_for_machine_status "$AIO_METRICS_TOPIC"
test_for_total_counter "$AIO_METRICS_TOPIC"