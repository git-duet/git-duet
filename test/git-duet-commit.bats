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

@test "does not rotate author by default" {
  git duet -q jd fb

  add_file first.txt
  git duet-commit -q -m 'Testing jd as author, fb as committer'
  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'

  add_file second.txt
  git duet-commit -q -m 'Testing jd remains author, fb remains committer'
  git log -1 --format='%an <%ae>'
  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'
}

@test "respects GIT_DUET_ROTATE_AUTHOR" {
  git duet -q jd fb

  add_file first.txt
  GIT_DUET_ROTATE_AUTHOR=1 git duet-commit -q -m 'Testing jd as author, fb as committer'
  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'

  add_file second.txt
  GIT_DUET_ROTATE_AUTHOR=1 git duet-commit -q -m 'Testing fb as author, jd as committer'
  run git log -1 --format='%an <%ae>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
}

@test "GIT_DUET_ROTATE_AUTHOR updates the correct config" {
  git duet -q -g jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane@hamsters.biz.local'

  add_file first.txt
  GIT_DUET_ROTATE_AUTHOR=1 git duet-commit -q -m 'Testing jd as author, fb as committer'
  assert_success

  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'f.bar@hamster.info.local'
}

@test "GIT_DUET_ROTATE_AUTHOR can understand and rotate teams" {
  git team -q -g jd fb on
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane@hamsters.biz.local'

  add_file first.txt
  GIT_DUET_ROTATE_AUTHOR=1 git duet-commit -q -m 'Testing jd as author, fb and on as team committers'
  assert_success

  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'f.bar@hamster.info.local'
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-committer-email"
  assert_success 'oscar@hamster.info.local, jane@hamsters.biz.local'

  add_file second.txt
  GIT_DUET_ROTATE_AUTHOR=1 git duet-commit -q -m 'Testing fb as author, on and jd as team committers'
  assert_success

  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'oscar@hamster.info.local'
}

@test "does not update mtime when rotating committer" {
  git duet -q jd fb
  git config --unset-all "$GIT_DUET_CONFIG_NAMESPACE.mtime"
  add_file
  GIT_DUET_ROTATE_AUTHOR=1 git duet-commit -q -m 'Testing mtime not set'
  assert_success
  run git config "$GIT_DUET_CONFIG_NAMESPACE.mtime"
  assert_equal 1 $status
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

@test "does not include Signed-off-by when soloing" {
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

@test "does not panic if no duet pair set" {
  add_file
  run git duet-commit -q -m 'Testing set of alpha as author'
  assert_line "git-author not set"
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
