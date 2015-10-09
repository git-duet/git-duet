#!/usr/bin/env bats

load test_helper

@test "lists the alpha of the duet as author in the log" {
  create_branch_commit
  git duet -q jd fb
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'
  git duet-merge new_branch
  run git log -1 --format='%an <%ae>'

  assert_success 'Jane Doe <jane@hamsters.biz.local>'
}

@test "lists the omega of the duet as committer in the log" {
  create_branch_commit
  git duet -q jd fb
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'
  git duet-merge new_branch -q
  run git log -1 --format='%cn <%ce>'

  assert_success 'Frances Bar <f.bar@hamster.info.local>'
}

@test "is a merge commit" {
  create_branch_commit
  git duet -q jd fb
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'
  git duet-merge new_branch -q

  assert_head_is_merge
}

@test "does not rotate author by default" {
  git duet -q jd fb

  create_branch_commit branch_one branch_file_one
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'
  git duet-merge branch_one -q

  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'

  create_branch_commit branch_two branch_file_two
  add_file yet_another_commit.txt
  git commit -q -m 'Avoid fast-forward'
  git duet-merge branch_two -q

  git log -1 --format='%an <%ae>'
  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'
}

@test "respects GIT_DUET_ROTATE_AUTHOR" {
  git duet -q jd fb

  create_branch_commit branch_one branch_file_one
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'
  GIT_DUET_ROTATE_AUTHOR=1 git duet-merge branch_one -q

  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'

  create_branch_commit branch_two branch_file_two
  add_file yet_another_commit.txt
  git commit -q -m 'Avoid fast-forward'
  GIT_DUET_ROTATE_AUTHOR=1 git duet-merge branch_two -q

  run git log -1 --format='%an <%ae>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
}

@test "GIT_DUET_ROTATE_AUTHOR updates the correct config" {
  git duet -q -g jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane@hamsters.biz.local'

  create_branch_commit branch_one branch_file_one
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'
  GIT_DUET_ROTATE_AUTHOR=1 git duet-merge branch_one -q
  assert_success

  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'f.bar@hamster.info.local'
}

@test "does not update mtime when rotating committer" {
  git duet -q jd fb
  git config --unset-all "$GIT_DUET_CONFIG_NAMESPACE.mtime"

  create_branch_commit branch_one branch_file_one
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'
  GIT_DUET_ROTATE_AUTHOR=1 git duet-merge branch_one -q
  assert_success

  run git config "$GIT_DUET_CONFIG_NAMESPACE.mtime"
  assert_equal 1 $status
}

@test "lists the soloist as author in the log" {
  git solo -q jd

  create_branch_commit branch_one branch_file_one
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'
  git duet-merge branch_one -q

  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
}

@test "lists the soloist as committer in the log" {
  git solo -q jd

  create_branch_commit branch_one branch_file_one
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'
  git duet-merge branch_one -q

  run git log -1 --format='%cn <%ce>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
}

@test "does not include Signed-off-by when soloing" {
  git solo -q jd

  create_branch_commit branch_one branch_file_one
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'
  git duet-merge branch_one -q

  run grep 'Signed-off-by' .git/COMMIT_EDITMSG
  assert_failure ''
}

@test "rejects commits with no author" {
  create_branch_commit branch_one branch_file_one
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'

  run git duet-merge branch_one -q

  assert_failure
}

@test "writes mtime to config" {
  git duet jd fb

  create_branch_commit branch_one branch_file_one
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'
  git duet-merge branch_one -q

  run git config "$GIT_DUET_CONFIG_NAMESPACE.mtime"
  assert_success
}

@test "does not panic if no duet pair set" {
  create_branch_commit branch_one branch_file_one
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'

  run git duet-merge branch_one -q

  assert_line "git-author not set"
}

@test "rejects commits with stale soloists with hook" {
  # if in CI, git-duet-pre-commit will not be in the PATH
  # exposed to git hooks
  if [ -n "$CI" ] ; then
    skip "cannot test commit hook on CI without sudo"
  fi

  create_branch_commit branch_one branch_file_one

  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'

  git solo -q jd
  git duet-install-hook -q
  git config --unset-all "$GIT_DUET_CONFIG_NAMESPACE.mtime"

  run git duet-merge branch_one -q

  assert_failure
  assert_line "your git duet settings are stale"
}

@test "rejects commits with stale duetists with hook" {
  # if in CI, git-duet-pre-commit will not be in the PATH
  # exposed to git hooks
  if [ -n "$CI" ] ; then
    skip "cannot test commit hook on CI without sudo"
  fi

  create_branch_commit branch_one branch_file_one
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'

  git duet -q jd fb
  git duet-install-hook -q
  git config --unset-all "$GIT_DUET_CONFIG_NAMESPACE.mtime"

  run git duet-merge branch_one -q

  assert_failure
  assert_line "your git duet settings are stale"
}
