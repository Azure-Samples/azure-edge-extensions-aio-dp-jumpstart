#!/bin/bash

rm -rf $WORKSPACE

pkill run-input.sh
pkill inotifywait
pkill run-output.sh
pkill mosquitto_sub
pkill run-zurich-validation.sh