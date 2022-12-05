#!/usr/bin/env bash
set -eou pipefail

cd "$(dirname "$0")"
source ./api-test.framework.sh
run-tests "${@:-add-and-delete-user}"
