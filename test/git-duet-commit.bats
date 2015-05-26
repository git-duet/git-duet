#!/usr/bin/env bats

load test_helper

@test "lists the alpha of the duet as author in the log" {
  git duet -q jd fb
  add_file
  git duet-commit -q -m 'Testing set of alpha as author'
  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
}

@test "lists the omega of the duet as committer in the log" {
  git duet -q jd fb
  add_file
  git duet-commit -q -m 'Testing set of omega as committer'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'
}

@test "lists the soloist as author in the log" {
  git solo -q jd
  add_file
  git duet-commit -q -m 'Testing set of soloist as author'
  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
}

@test "lists the soloist as committer in the log" {
  git solo -q jd
  add_file
  git duet-commit -q -m 'Testing set of soloist as committer'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
}

@test "does not inclued Signed-off-by whene soloing" {
  git solo -q jd
  add_file
  git duet-commit -q -m 'Testing omitting signoff'
  run grep 'Signed-off-by' .git/COMMIT_EDITMSG
  assert_failure ''
}

@test "rejects commits with no author" {
  add_file
  run git duet-commit -q -m 'Testing commit with no author'
  assert_failure
}

@test "writes mtime to config" {
  git duet jd fb
  add_file
  git duet-commit -q -m 'Testing set of alpha as author'
  run git config "$GIT_DUET_CONFIG_NAMESPACE.mtime"
  assert_success
}

@test "rejects commits with stale soloists with hook" {
  # if in CI, git-duet-pre-commit will not be in the PATH
  # exposed to git hooks
  if [ -n "$CI" ] ; then
    skip "cannot test commit hook on CI without sudo"
  fi

  git solo -q jd
  git duet-install-hook -q
  git config --unset-all "$GIT_DUET_CONFIG_NAMESPACE.mtime"
  add_file
  run git duet-commit -q -m 'Testing stale hook fire'

  assert_failure
  assert_line "your git duet settings are stale"
}

@test "rejects commits with stale duetists with hook" {
  # if in CI, git-duet-pre-commit will not be in the PATH
  # exposed to git hooks
  if [ -n "$CI" ] ; then
    skip "cannot test commit hook on CI without sudo"
  fi

  git duet -q jd fb
  git duet-install-hook -q
  git config --unset-all "$GIT_DUET_CONFIG_NAMESPACE.mtime"
  add_file
  run git duet-commit -q -m 'Testing stale hook fire'

  assert_failure
  assert_line "your git duet settings are stale"
}
