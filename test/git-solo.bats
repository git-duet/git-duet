#!/usr/bin/env bats

load test_helper

@test "version is displayed" {
  run git solo -v
  if ! echo "$output" | grep -o -E "^[0-9]+\.[0-9]+\.[0-9]+.* \('[a-f0-9]{40}'\)$" ; then
    echo "expected '$output' to match version spec" | flunk
  fi
}

@test "output is displayed" {
  run git solo jd
  assert_line "GIT_AUTHOR_NAME='Jane Doe'"
  assert_line "GIT_AUTHOR_EMAIL='jane@hamsters.biz.local'"
}

@test "output is not displayed when quieted" {
  git solo jd -q
  assert_success ""
}

@test "caches the git user initials as author initials" {
  git solo -q jd
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-initials"
  assert_success 'jd'
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
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'abe@hamster.info.local'
}

@test "builds email from name" {
  git solo zp
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'z.pants@hamster.info.local'
}

@test "builds email from two names" {
  git solo on
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'oscar@hamster.info.local'
}

@test "looks up external email" {
  GIT_DUET_EMAIL_LOOKUP_COMMAND=$GIT_DUET_TEST_LOOKUP git solo -q jd
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane_doe@lookie.me.local'
}

@test "uses custom email template when provided" {
  local suffix=$RANDOM

  set_custom_email_template "{{with split .Name \" \"}}{{with index . 0}}{{toLower . }}{{end}}.{{with index . 1}}{{toLower . }}{{end}}{{end}}$suffix@mompopshop.local"

  git solo -q zp
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success "zubaz.pants$suffix@mompopshop.local"

  clear_custom_email_template
}

@test "unsets git committer email after duet" {
  git duet -q jd fb
  git solo -q jd
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-email"
  assert_success ""
}

@test "unsets git committer initials after duet" {
  git duet -q jd fb
  git solo -q jd
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-initials"
  assert_success ""
}

@test "respects GIT_DUET_GLOBAL" {
  GIT_DUET_GLOBAL=1 git solo jd
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane@hamsters.biz.local'
}

@test "sets the git user email globally" {
  git solo -g jd
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane@hamsters.biz.local'
}

@test "sets the git user name globally" {
  git solo -g -q jd
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-name"
  assert_success 'Jane Doe'
}

@test "unsets git committer email after duet globally" {
  git duet -g -q jd fb
  git solo -g -q jd
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-committer-email"
  assert_success ""
}

@test "reads configuration globally" {
  git solo -g -q jd
  git solo fb
  run git duet -g
  assert_success
  assert_line "GIT_AUTHOR_NAME='Jane Doe'"
  assert_line "GIT_AUTHOR_EMAIL='jane@hamsters.biz.local'"
}

@test "does not sets git user.name and user.email by default" {
  git solo -q jd
  run git config "user.name"
  assert_success 'Test User'
  run git config "user.email"
  assert_success 'test@example.com'
}

@test "sets git user.name and user.email if GIT_DUET_SET_GIT_USER_CONFIG" {
  GIT_DUET_SET_GIT_USER_CONFIG=1 git solo -q jd
  run git config "user.name"
  assert_success 'Jane Doe'
  run git config "user.email"
  assert_success 'jane@hamsters.biz.local'
}

@test "sets git user.name and user.email if GIT_DUET_CO_AUTHORED_BY" {
  # since GIT_DUET_CO_AUTHORED_BY implicitly sets GIT_DUET_SET_GIT_USER_CONFIG
  GIT_DUET_CO_AUTHORED_BY=1 git solo -q jd
  run git config "user.name"
  assert_success 'Jane Doe'
  run git config "user.email"
  assert_success 'jane@hamsters.biz.local'
}

@test "prints current config" {
  git solo -q al
  run git solo
  assert_line "GIT_AUTHOR_NAME='Abraham Lincoln'"
  assert_line "GIT_AUTHOR_EMAIL='abe@hamster.info.local'"
}

@test "prints error output when commands fail" {
  cd /tmp

  run git config user.name foo
  expected_output="$output"

  run git solo al
  assert_failure
  echo "output $output"
  echo "expected output $expected_output"
  assert_line "$expected_output"
}

@test "respects git root level .git-authors configuration" {
  setup_root_git_author

  GIT_DUET_SET_GIT_USER_CONFIG=1 git solo -q fc
  run git config "user.name"
  assert_success 'Frances Car'
  run git config "user.email"
  assert_success 'f.car@banana.info.local'
}

@test "does not error when run outside of a git repository" {
  run git solo -g jd
  assert_success

  mkdir ${GIT_DUET_TEST_DIR}/no-repo
  cd ${GIT_DUET_TEST_DIR}/no-repo

  unset GIT_DUET_AUTHORS_FILE
  git solo
  run git solo
  assert_success
  assert_line "GIT_AUTHOR_NAME='Jane Doe'"
  assert_line "GIT_AUTHOR_EMAIL='jane@hamsters.biz.local'"
}

@test "does not write Co-authored-by trailer if GIT_DUET_CO_AUTHORED_BY is set" {
  GIT_DUET_CO_AUTHORED_BY=1 git solo -q jd
  add_file first.txt
  git commit -q -m 'I do not have a co-author'
  run grep 'Co-authored-by:' .git/COMMIT_EDITMSG
  assert_failure
}

@test "--show option prints current author and committer if set" {
  git duet jd fb
  run git solo --show
  assert_line "GIT_AUTHOR_NAME='Jane Doe'"
  assert_line "GIT_AUTHOR_EMAIL='jane@hamsters.biz.local'"
  assert_line "GIT_COMMITTER_NAME='Frances Bar'"
  assert_line "GIT_COMMITTER_EMAIL='f.bar@hamster.info.local'"
}

@test "When GIT_DUET_DEFAULT_UPDATE is set, git-solo with no args removes the duet configuration" {
  git duet jd fb
  GIT_DUET_DEFAULT_UPDATE=1 git solo
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_failure
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-email"
  assert_success ""
}