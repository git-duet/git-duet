#!/usr/bin/env bats

load test_helper

@test "version is displayed" {
  run git duet -v
  if ! echo "$output" | grep -o -E "^[0-9]\.[0-9]\.[0-9].* \('[a-f0-9]{40}'\)$" ; then
    echo "expected '$output' to match version spec" | flunk
  fi
}

@test "requires 2 or more users" {
  run git duet jd
  assert_failure 'must specify at least two sets of initials'
}

@test "allows 3 users" {
  git duet -q jd fb zs
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-initials"
  assert_success 'jd'
}

@test "sets the git user initials" {
  git duet -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-initials"
  assert_success 'jd'
}

@test "sets the git user name" {
  git duet -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-name"
  assert_success 'Jane Doe'
}

@test "sets the git user email" {
  git duet -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane@hamsters.biz.local'
}

@test "sets the git committer initials" {
  git duet -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-initials"
  assert_success 'fb'
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
  local suffix=$RANDOM

  set_custom_email_template "{{with split .Name \" \"}}{{with index . 0}}{{toLower . }}{{end}}.{{with index . 1}}{{toLower . }}{{end}}{{end}}$suffix@mompopshop.local"

  git duet -q zp fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success "zubaz.pants$suffix@mompopshop.local"

  clear_custom_email_template
}

@test "sets the git user email globally" {
  git duet -g -q jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane@hamsters.biz.local'
}

@test "sets the git user initials globally" {
  git duet -g -q jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-initials"
  assert_success 'jd'
}

@test "sets the git user name globally" {
  git duet -g -q jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-name"
  assert_success 'Jane Doe'
}

@test "sets the git committer email globally" {
  git duet -g -q jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-committer-name"
  assert_success 'Frances Bar'
}

@test "sets the git committer initials globally" {
  git duet -g -q jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-committer-initials"
  assert_success 'fb'
}

@test "sets the git committer name globally" {
  git duet -g -q jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-committer-email"
  assert_success 'f.bar@hamster.info.local'
}

@test "reads configuration globally" {
  git duet -g -q jd fb
  git duet fb on
  run git duet -g
  assert_success
  assert_line "GIT_AUTHOR_NAME='Jane Doe'"
  assert_line "GIT_AUTHOR_EMAIL='jane@hamsters.biz.local'"
  assert_line "GIT_COMMITTER_NAME='Frances Bar'"
  assert_line "GIT_COMMITTER_EMAIL='f.bar@hamster.info.local'"
}

@test "does not sets git user.name and user.email by default" {
  git duet -q jd fb
  run git config "user.name"
  assert_success 'Test User'
  run git config "user.email"
  assert_success 'test@example.com'
}

@test "sets git user.name and user.email if GIT_DUET_SET_GIT_USER_CONFIG" {
  GIT_DUET_SET_GIT_USER_CONFIG=1 git duet -q jd fb
  run git config "user.name"
  assert_success 'Jane Doe'
  run git config "user.email"
  assert_success 'jane@hamsters.biz.local'
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

@test "honors source when printing config" {
  git duet -q -g on jd
  git solo fb
  run git duet
  assert_line "GIT_AUTHOR_NAME='Frances Bar'"
  assert_line "GIT_AUTHOR_EMAIL='f.bar@hamster.info.local'"
  assert_line "GIT_COMMITTER_NAME='Frances Bar'"
  assert_line "GIT_COMMITTER_EMAIL='f.bar@hamster.info.local'"
}
