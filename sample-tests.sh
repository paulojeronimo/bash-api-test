#vim: syntax=bash

declare -r GET_USERS='GET /users'
declare -r POST_USERS='POST /users'

get-users() {
  $GET_USERS
  assert 'response should not be null' \
    '[ "${response:-}" ]'
  local expected=200; assert "http_status should be equals to $expected" \
    '[ "$http_status" = $expected ]'
  expected=${1:-2}; assert "the number of users should be equals to $expected" \
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
  local expected=201; assert "http_status should be equals to $expected" \
    '[ "$http_status" = $expected ]'
  declare -r user_json=$(map-to-json user)
  get-users 3
  declare -r last_user_json=$(jq ".[-1]" <<< "$response_body")
  inspect user_json as-string
  inspect last_user_json as-string
  assert "last_user_json should be equals to user_json" \
    '[ "$last_user_json" = "$user_json" ]'
}
