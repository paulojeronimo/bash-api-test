#!/usr/bin/env bash
set -eou pipefail

SERVER_PATH=${SERVER_PATH:-':3000'}

cd "$(dirname "$0")"
source ./api-test.framework.sh
source ./${0/test./}
run-tests "$@"
