#vim: syntax=bash

declare -r GET_USERS='GET /users'
declare -r POST_USERS='POST /users'

get-users() {
  $GET_USERS
  assert response-available
  assert http-status 200
  assert expected ${1:-2} "the number of users should be equals to expected" \
    '[ $(jq ".|length" <<< "$response_body") = $expected ]'
}

test-get-users() {
  header "$GET_USERS"
  get-users
}

test-post-user() {
  declare -A user=([firstName]=Beltrano [lastName]=Santos [email]='beltranodossantos@example.com')
  user[id]=$(get-id-from-email ${user[email]})
  header "$POST_USERS" "with user[id] \"${user[id]}\""
  $POST_USERS $(map-to-args user)
  assert http-status 201
  get-users 3
  declare -r user_json=$(map-to-json user)
  declare -r last_user_json=$(jq ".[-1]" <<< "$response_body")
  assert equals user_json last_user_json
}
