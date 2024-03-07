#!/bin/bash

create_workspace() {
    local workspace=$1
    rm -rf "$WORKSPACE"
    mkdir -p "$WORKSPACE/logs"
}
