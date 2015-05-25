#!/usr/bin/env bats

load test_helper

@test "sets the git user name" {
  skip "TODO"
  git duet -q jd fb
  run git config user.name
  assert_success 'Jane Doe'
}

@test "sets the git user email" {
  skip "TODO"
  git duet -q jd fb
  run git config user.email
  assert_success 'jane@hamsters.biz.local'
}

@test "caches the git committer name" {
  skip "TODO"
  git duet -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-name"
  assert_success 'Frances Bar'
}

@test "caches the git committer email" {
  skip "TODO"
  git duet -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-email"
  assert_success 'f.bar@hamster.info.local'
}

@test "looks up external author email" {
  skip "TODO"
  GIT_DUET_EMAIL_LOOKUP_COMMAND=$GIT_DUET_TEST_LOOKUP git duet -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane_doe@lookie.me.local'
}

@test "looks up external committer email" {
  skip "TODO"
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

@test "uses custom email template for committer when provided" {
  skip "TODO"
  local suffix=$RANDOM

  set_custom_email_template "<%= \"#{author.split.first.downcase}#{author.split.last[0].chr.downcase}$suffix@mompopshop.local\" %>"

  git duet -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-email"
  assert_success "francesb$suffix@mompopshop.local"

  clear_custom_email_template
}
