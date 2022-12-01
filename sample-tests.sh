#vim: syntax=bash

source ./${TEST_SCRIPT%.sh}.lib.sh

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
