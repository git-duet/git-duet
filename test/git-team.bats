#!/usr/bin/env bats

load test_helper

@test "sets the git user initials" {
  git team -q jd fb on
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-initials"
  assert_success 'jd'
}

@test "sets the git user name" {
  git team -q jd fb on
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-name"
  assert_success 'Jane Doe'
}

@test "sets the git user email" {
  git team -q jd fb on
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane@hamsters.biz.local'
}

@test "sets the git committer initials" {
  git team -q jd fb on
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-initials"
  assert_success 'fb, on'
}

@test "caches the git committer name" {
  git team -q jd fb on
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-name"
  assert_success 'Frances Bar, Oscar'
}

@test "caches the git committer email" {
  git team -q jd fb on
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-email"
  assert_success 'f.bar@hamster.info.local, oscar@hamster.info.local'
}

@test "looks up external author email" {
  GIT_DUET_EMAIL_LOOKUP_COMMAND=$GIT_DUET_TEST_LOOKUP git team -q jd fb on
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane_doe@lookie.me.local'
}

@test "looks up external committer email" {
  GIT_DUET_EMAIL_LOOKUP_COMMAND=$GIT_DUET_TEST_LOOKUP git team -q on jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-email"
  assert_success 'jane_doe@lookie.me.local, fb9000@dalek.info.local'
}

@test "sets the git user email globally" {
  git team -g -q jd fb on
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane@hamsters.biz.local'
}

@test "sets the git user initials globally" {
  git team -g -q jd fb on
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-initials"
  assert_success 'jd'
}

@test "sets the git user name globally" {
  git team -g -q jd fb on
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-name"
  assert_success 'Jane Doe'
}

@test "sets the git committer email globally" {
  git team -g -q jd fb on
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-committer-name"
  assert_success 'Frances Bar, Oscar'
}

@test "sets the git committer initials globally" {
  git team -g -q jd fb on
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-committer-initials"
  assert_success 'fb, on'
}

@test "sets the git committer name globally" {
  git team -g -q jd fb on
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-committer-email"
  assert_success 'f.bar@hamster.info.local, oscar@hamster.info.local'
}

@test "output is displayed" {
  run git team jd fb on
  assert_line "GIT_AUTHOR_NAME='Jane Doe'"
  assert_line "GIT_AUTHOR_EMAIL='jane@hamsters.biz.local'"
  assert_line "GIT_COMMITTER_NAME='Frances Bar, Oscar'"
  assert_line "GIT_COMMITTER_EMAIL='f.bar@hamster.info.local, oscar@hamster.info.local'"
}

@test "output is not displayed when quieted" {
  run git team -q jd fb on
  assert_success ""
}

@test "prints current config" {
  git team -q jd fb on
  run git duet
  assert_line "GIT_AUTHOR_NAME='Jane Doe'"
  assert_line "GIT_AUTHOR_EMAIL='jane@hamsters.biz.local'"
  assert_line "GIT_COMMITTER_NAME='Frances Bar, Oscar'"
  assert_line "GIT_COMMITTER_EMAIL='f.bar@hamster.info.local, oscar@hamster.info.local'"
}

@test "honors source when printing config" {
  git team -q -g fb jd on
  git solo fb
  run git team
  assert_line "GIT_AUTHOR_NAME='Frances Bar'"
  assert_line "GIT_AUTHOR_EMAIL='f.bar@hamster.info.local'"
  assert_line "GIT_COMMITTER_NAME='Frances Bar'"
  assert_line "GIT_COMMITTER_EMAIL='f.bar@hamster.info.local'"
}

@test "lists the alpha of the team as author in the log" {
  git team -q jd fb on
  add_file
  git duet-commit -q -m 'testing set of alpha as author'
  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
}

@test "lists the rest of the team as committer in the log" {
  git team -q jd fb on
  add_file
  git duet-commit -q -m 'testing set of omega as committer'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Frances Bar, Oscar <f.bar@hamster.info.local, oscar@hamster.info.local>'
}
