#!/usr/bin/env bats

load test_helper

@test "sets the git user name" {
  git solo -q jd
  run git config user.name
  assert_success 'Jane Doe'
}

@test "output is displayed" {
  run git solo jd
  assert_line "GIT_AUTHOR_NAME='Jane Doe'"
  assert_line "GIT_AUTHOR_EMAIL='jane@hamsters.biz.local'"
  run git config user.name
  assert_success 'Jane Doe'
}

@test "output is not displayed when quieted" {
  git solo jd -q
  assert_success ""
  run git config user.name
  assert_success 'Jane Doe'
}

@test "sets the git user email" {
  git solo jd
  run git config user.email
  assert_success 'jane@hamsters.biz.local'
}

@test "caches the git user name as author name" {
  git solo -q jd
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-name"
  assert_success 'Jane Doe'
}

@test "caches the git user email as author email" {
  git solo -q jd
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane@hamsters.biz.local'
}

@test "builds email from id" {
  git solo al
  run git config user.email
  assert_success 'abe@hamster.info.local'
}

@test "looks up external email" {
  GIT_DUET_EMAIL_LOOKUP_COMMAND=$GIT_DUET_TEST_LOOKUP git solo -q jd
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane_doe@lookie.me.local'
}

@test "uses custom email template when provided" {
  skip "TODO"
  local suffix=$RANDOM

  set_custom_email_template "awk '{ print tolower(substr(\$1, 1, 1)) \".\" tolower(substr($2, 1))} \"$suffix@mompopshop.local\""

  git solo -q zp
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success "zubazp$suffix@mompopshop.local"

  clear_custom_email_template
}

@test "prints current config" {
  git solo -q al
  run git solo
  assert_line "$GIT_DUET_CONFIG_NAMESPACE.git-author-name Abraham Lincoln"
  assert_line "$GIT_DUET_CONFIG_NAMESPACE.git-author-email abe@hamster.info.local"
  # TODO duet.env.mtime 1432578614
}

@test "sets the git user email globally" {
  git solo jd
  run git config --global user.email
  assert_success 'jane@hamsters.biz.local'
}

@test "sets the git user name globally" {
  git solo -g -q jd
  run git config --global user.name
  assert_success 'Jane Doe'
}
