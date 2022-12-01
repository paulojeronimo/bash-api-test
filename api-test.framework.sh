# vim: syntax=bash

:<<'USAGE'
Usage:
$ $0 <all|test-1 ... test-n>

Examples:
$ $0 all
$ $0 test-1
$ $0 test-1 test-2
USAGE

: ${JQ=$(command -v jq)}
: ${HTTP=$(command -v http)}
TEST_SCRIPT=$(caller | cut -d ' ' -f2)
TEST_SCRIPT=${TEST_SCRIPT/test./}
HTTP_TIMEOUT=${HTTP_TIMEOUT:-4.5}
LOG=${LOG:-${TEST_SCRIPT%.sh}.log}

jq() {
  $JQ -S --ascii-output "$@"
}

http() {
  $HTTP --timeout=$HTTP_TIMEOUT "$@"
}

inspect() {
  echo -ne "\tINSPECTION: "
  case "${2:-}" in
    as-string) echo "$1=$(echo ${!1})";;
    as-json) echo "$1=\n${!1}";;
    *) echo "$1=${!1}"
  esac
}

hdump() {
  echo "Dumping $1 (${!1})":
  #echo -n "hexdump: "; hexdump -ve '1/1 "%.2x"' <<< "${!1}"; echo
  echo -n "xxd    : "; xxd -p <<< "${!1}" | tr -d '\n'; echo
  echo -n "sha1sum: "; sha1sum <<< "${!1}"; echo
}

ok() {
  if ! [ "${1:-}" ]; then set -- executed successfuly!; fi
  echo -e "\t\033[;32mOK: "$@" \033[0m "
}

fail() {
  local _continue=false
  [ "$1" ] || set -- failed! See $LOG.
  case "$1" in
    -c) shift; _continue=true;;
  esac
  echo -e "\t\033[;31mFAIL: "$@" \033[0m "
  if ! $_continue; then exit 1; fi
}

assert() {
  local expected
  declare -r _type=$1; shift
  case "$_type" in
    response-available)
      set -- 'response should no be null' \
        '[ "${response:-}" ]'
      ;;
    http-status)
      expected=$1; shift;
      set -- "http_status should be equals to $expected" \
        '[ "$http_status" = $expected ]'
      ;;
    expected)
      expected=$1; shift;
      set -- "${1/expected/$expected}"
      ;;
    equals)
      local expected2
      expected=$1; shift
      expected2=$1; shift
      set -- "$expected should be equals to $expected2" \
        '[ "${!expected}" = "${!expected2}" ]'
      ;;
    *)
      error "assert syntax error!"
  esac
  declare -r assertion=$1; shift
  declare -r assessment=$@
  echo -e "\tASSERTION: $assertion"
  #echo -e "\tTEST: $assessment"
  if eval $assessment; then ok; else fail -c; fi
}

error() {
  echo -e "\t\033[;31mERROR: "$@" \033[0m "
}

header() {
  echo ${FUNCNAME[1]}: Testing "$@" ...
}

get-lines-from-beginning-to-empty-line() {
  sed -n '/^\r$/,$!p' <<< "$1"
}

get-lines-from-empty-line-to-end() {
  sed '1,/^\r$/ d' <<< "$1"
}

set-response() {
  response_header=$(get-lines-from-beginning-to-empty-line "$response")
  http_status=$(sed -n '/HTTP\//p' <<< "$response_header" | cut -d' ' -f2)
  response_body=$(get-lines-from-empty-line-to-end "$response")
}

unset-response() {
  unset response response_header http_status response_body
}

GET() {
  local http_params='--print=hb'
  while [[ ${1:-} =~ ^- ]]
  do
    http_params="$http_params $1"
    shift
  done
  if response=$(http $http_params "${SERVER_PATH}$1" 2> "$LOG")
  then
    set-response
  else
    unset-response
  fi
}

POST() {
  local http_params='--print=hb'
  while [[ ${1:-} =~ ^- ]]
  do
    http_params="$http_params $1"
    shift
  done
  local path="$SERVER_PATH$1"; shift
  if response=$(http $http_params "$path" "$@" 2> "$LOG")
  then
    set-response
  else
    unset-response
  fi
}

json() {
  local value
  while [ "${1:-}" ]
  do
    value="${value:-} $1"
    shift
  done
  [ "${value:-}" ] && \
    $HTTP --offline --sorted --print=B $SERVER_PATH $value | jq
}

map-to-args() {
  declare -nl map=$1
  local result=
  for key in "${!map[@]}"
  do
    result="$result $key=${map[$key]}"
  done
  echo $result
}

map-to-json() {
  json $(map-to-args $1)
}

get-id-from-email() {
  cut -d'@' -f1 <<< $1
}

validate-tools-or-exit() {
  local valid=true
  for tool in JQ HTTP
  do
    [ "${!tool}" ] || {
      fail -c \"${tool,,}\" is not installed!
      valid=false
    }
  done
  $valid || { error "Please, verify the problems above!"; exit 1; }
}

print-usage-details-or-go-ahead() {
  TESTS=($(sed -n 's/test-\(.*\)() {/\1/p' $TEST_SCRIPT | tr '\n' ' '))
  if [ $# = 0 ]
  then
    sed -n "/^:<<'USAGE'$/,/^USAGE$/{//!p}" ${BASH_SOURCE[0]} | \
    sed "
      s,\$0,$TEST_SCRIPT,g
      s,test-1,${TESTS[0]},g
      s,test-n,${TESTS[-1]},g
    " | \
    if (( ${#TESTS[@]} >= 2 ))
    then
      sed "s,test-2,${TESTS[1]},g"
    else
      sed "$ d"
    fi
    exit 0
  fi
}

run-tests() {
  validate-tools-or-exit
  print-usage-details-or-go-ahead "$@"
  while [ "$1" ]
  do
    if [ $1 = all ]; then shift; set -- ${TESTS[@]}; fi
    type test-$1 &> /dev/null || {
      error "\"test-$1()\" wasn't coded in $TEST_SCRIPT"
      exit 1
    }
    echo "Running \"test-$1\" ..."
    ( test-$1 ) || error "\"test-$1\" returned $?"
    shift
    [ "${1:-}" ] && echo "----" || break
  done
}

save-function() {
  local orig_func=$(declare -f $1)
  local newname_func="$2${orig_func#$1}"
  eval "$newname_func"
}
