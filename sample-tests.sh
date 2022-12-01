#vim: syntax=bash

test-get-users() {
  header "$GET_USERS"
  get-users-and-assert-number-of-users 2
}

test-add-and-delete-user() {
  declare -A new_user=([firstName]=Beltrano \
    [lastName]=Santos [email]='beltranodossantos@example.com')
  new_user[id]=$(get-id-from-email ${new_user[email]})
  header "${FUNCNAME#test-}" "with id \"${new_user[id]}\""

  local last_user_before_add=$(get-last-added-user) ||
    fail "Could not get last_user_before_add"

  $POST_USERS $(map-to-args new_user)
  assert http-status 201
  get-users-and-assert-number-of-users 3
  assert last-added-user new_user

  $DELETE_USERS ${new_user[id]}
  get-users-and-assert-number-of-users 2
  assert last-added-user --as-json last_user_before_add
}
