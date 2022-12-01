#!/usr/bin/env bash
set -eou pipefail

cd "$(dirname "$0")"
source ./api-test.framework.sh
source $TEST_SCRIPT
run-tests "$@"
