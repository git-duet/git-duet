#!/usr/bin/env bats

load test_helper

@test "sets the git user name" {
  git duet -q jd fb
  run git config user.name
  assert_success 'Jane Doe'
}

@test "sets the git user email" {
  git duet -q jd fb
  run git config user.email
  assert_success 'jane@hamsters.biz.local'
}

@test "caches the git committer name" {
  git duet -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-name"
  assert_success 'Frances Bar'
}

@test "caches the git committer email" {
  git duet -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-email"
  assert_success 'f.bar@hamster.info.local'
}

@test "looks up external author email" {
  GIT_DUET_EMAIL_LOOKUP_COMMAND=$GIT_DUET_TEST_LOOKUP git duet -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane_doe@lookie.me.local'
}

@test "looks up external committer email" {
  GIT_DUET_EMAIL_LOOKUP_COMMAND=$GIT_DUET_TEST_LOOKUP git duet -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-email"
  assert_success 'fb9000@dalek.info.local'
}

@test "uses custom email template for author when provided" {
  skip "TODO"
  local suffix=$RANDOM

  set_custom_email_template "<%= \"#{author.split.first.downcase}#{author.split.last[0].chr.downcase}$suffix@mompopshop.local\" %>"

  git duet zp fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success "zubazp$suffix@mompopshop.local"

  clear_custom_email_template
}

@test "sets the git user email globally" {
  git duet -g -q jd fb
  run git config --global user.email
  assert_success 'jane@hamsters.biz.local'
}

@test "sets the git user name globally" {
  git duet -g -q jd fb
  run git config --global user.name
  assert_success 'Jane Doe'
}

@test "sets the git committer email globally" {
  git duet -g -q jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-committer-name"
  assert_success 'Frances Bar'
}

@test "sets the git committer name globally" {
  git duet -g -q jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-committer-email"
  assert_success 'f.bar@hamster.info.local'
}

@test "output is displayed" {
  run git duet jd fb
  assert_line "GIT_AUTHOR_NAME='Jane Doe'"
  assert_line "GIT_AUTHOR_EMAIL='jane@hamsters.biz.local'"
  assert_line "GIT_COMMITTER_NAME='Frances Bar'"
  assert_line "GIT_COMMITTER_EMAIL='f.bar@hamster.info.local'"
}

@test "output is not displayed when quieted" {
  run git duet -q jd fb
  assert_success ""
}

@test "prints current config" {
  git duet -q jd fb
  run git duet
  assert_line "GIT_AUTHOR_NAME='Jane Doe'"
  assert_line "GIT_AUTHOR_EMAIL='jane@hamsters.biz.local'"
  assert_line "GIT_COMMITTER_NAME='Frances Bar'"
  assert_line "GIT_COMMITTER_EMAIL='f.bar@hamster.info.local'"
}
