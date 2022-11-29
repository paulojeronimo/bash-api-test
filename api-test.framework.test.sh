#!/usr/bin/env bash

source ./api-test.framework.sh

http_status=200
http-status print
http-status test 200 && echo ok || echo fail
http-status || echo no-parameter-fail
