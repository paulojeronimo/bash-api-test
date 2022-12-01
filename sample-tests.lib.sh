#vim: syntax=bash

declare -r GET_USERS='GET /users'
declare -r POST_USERS='POST /users'
declare -r DELETE_USERS='DELETE /users'
save-function assert default-assert

get-last-added-user-from-response-body() {
  if [ "$response_body" ]
  then
    jq '.[-1]' <<< "$response_body"
  else
    return 1
  fi
}

assert() {
  case "$1" in
    last-added-user)
      shift
      if [ "$1" = --as-json ]
      then
        shift
        declare -r user=${!1}
      else
        declare -r user=$(map-to-json $1)
      fi
      declare -r last_added_user=$(get-last-added-user-from-response-body)
      default-assert equals user last_added_user
      ;;
    number-of-users)
      shift
      default-assert expected $1 "the number of users should be equals to expected" \
        '[ $(jq ".|length" <<< "$response_body") = $expected ]'
      ;;
    *) default-assert "$@"
  esac
}

get-last-added-user() {
  $GET_USERS
  if [ "$http_status" = 200 ]
  then
    get-last-added-user-from-response-body
  else
    return 1
  fi
}

get-users-and-assert-number-of-users() {
  $GET_USERS
  assert response-available
  assert http-status 200
  assert number-of-users $1
}
