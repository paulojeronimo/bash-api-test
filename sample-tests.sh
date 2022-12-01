#vim: syntax=bash

declare -r GET_USERS='GET /users'
declare -r POST_USERS='POST /users'
save-function assert default-assert

assert() {
  case "$1" in
    last-user)
      shift
      declare -r user_json=$(map-to-json $1)
      declare -r last_user_json=$(jq ".[-1]" <<< "$response_body")
      default-assert equals user_json last_user_json
      ;;
    number-of-users)
      shift
      default-assert expected $1 "the number of users should be equals to expected" \
        '[ $(jq ".|length" <<< "$response_body") = $expected ]'
      ;;
    *) default-assert "$@"
  esac
}

get-users-and-assert-number-of-users() {
  $GET_USERS
  assert response-available
  assert http-status 200
  assert number-of-users $1
}

test-get-users() {
  header "$GET_USERS"
  get-users-and-assert-number-of-users 2
}

test-post-user() {
  declare -A user=([firstName]=Beltrano [lastName]=Santos [email]='beltranodossantos@example.com')
  user[id]=$(get-id-from-email ${user[email]})
  header "$POST_USERS" "with user[id] \"${user[id]}\""
  $POST_USERS $(map-to-args user)
  assert http-status 201
  get-users-and-assert-number-of-users 3
  assert last-user user
}
