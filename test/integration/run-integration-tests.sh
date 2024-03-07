#!/bin/bash

. ../utils/set-colors.sh

# Turn off job control
set +m

echo "== Running Validation Tests =="

./run-zurich-validation.sh

trap "trap - SIGTERM && kill -- -$$ 2>/dev/null" SIGINT SIGTERM EXIT

read -p "Press any key to continue (and clean workspace) ..." </dev/tty

blue "Cleaning ..."

rm -rf $WORKSPACE
