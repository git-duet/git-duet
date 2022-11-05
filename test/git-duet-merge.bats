#!/usr/bin/env bats

load test_helper

@test "lists the alpha of the duet as author in the log" {
  git duet -q jd fb
  create_branch_commit
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'
  git duet-merge new_branch
  run git log -1 --format='%an <%ae>'

  assert_success 'Jane Doe <jane@hamsters.biz.local>'
}

@test "lists the omega of the duet as committer in the log" {
  git duet -q jd fb
  create_branch_commit
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'
  git duet-merge new_branch -q
  run git log -1 --format='%cn <%ce>'

  assert_success 'Frances Bar <f.bar@hamster.info.local>'
}

@test "is a merge commit" {
  git duet -q jd fb
  create_branch_commit
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'
  git duet-merge new_branch -q

  assert_head_is_merge
}

@test "writes Signed-off-by trailer for the merge commit" {
  git duet -q jd fb
  create_branch_commit
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'
  git duet-merge new_branch -q

  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  grep 'Signed-off-by: Frances Bar <f.bar@hamster.info.local>' .git/COMMIT_EDITMSG
}

@test "does not allow multiple committers by default" {
  git duet -q jd fb zs
  create_branch_commit
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'
  git duet-merge new_branch -q

  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  [[ $(grep -o 'Signed-off-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 1 ]]
  grep 'Signed-off-by: Frances Bar <f.bar@hamster.info.local>' .git/COMMIT_EDITMSG
}

@test "allow multiple committers if GIT_DUET_ALLOW_MULTIPLE_COMMITTERS" {
  export GIT_DUET_ALLOW_MULTIPLE_COMMITTERS=1
  git duet -q jd fb zs
  create_branch_commit
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'
  git duet-merge new_branch -q

  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  [[ $(grep -o 'Signed-off-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 2 ]]
  grep 'Signed-off-by: Frances Bar <f.bar@hamster.info.local>' .git/COMMIT_EDITMSG
  grep 'Signed-off-by: Zubaz Shirts <z.shirts@pika.info.local>' .git/COMMIT_EDITMSG
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

@test "respects GIT_DUET_ROTATE_AUTHOR with three contributors" {
  git duet -q jd fb zs

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
  assert_success 'Zubaz Shirts <z.shirts@pika.info.local>'

  create_branch_commit branch_three branch_file_three
  add_file still_committing.txt
  git commit -q -m 'Avoid fast-forward'
  GIT_DUET_ROTATE_AUTHOR=1 git duet-merge branch_three -q

  run git log -1 --format='%an <%ae>'
  assert_success 'Zubaz Shirts <z.shirts@pika.info.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
}

@test "respects GIT_DUET_ROTATE_AUTHOR with three contributors and GIT_DUET_ALLOW_MULTIPLE_COMMITTERS" {
  export GIT_DUET_ALLOW_MULTIPLE_COMMITTERS=1
  git duet -q jd fb zs

  create_branch_commit branch_one branch_file_one
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'
  GIT_DUET_ROTATE_AUTHOR=1 git duet-merge branch_one -q

  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  [[ $(grep -o 'Signed-off-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 2 ]]
  grep 'Signed-off-by: Frances Bar <f.bar@hamster.info.local>' .git/COMMIT_EDITMSG
  grep 'Signed-off-by: Zubaz Shirts <z.shirts@pika.info.local>' .git/COMMIT_EDITMSG

  create_branch_commit branch_two branch_file_two
  add_file yet_another_commit.txt
  git commit -q -m 'Avoid fast-forward'
  GIT_DUET_ROTATE_AUTHOR=1 git duet-merge branch_two -q

  run git log -1 --format='%an <%ae>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'
  [[ $(grep -o 'Signed-off-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 2 ]]
  grep 'Signed-off-by: Zubaz Shirts <z.shirts@pika.info.local>' .git/COMMIT_EDITMSG
  grep 'Signed-off-by: Jane Doe <jane@hamsters.biz.local>' .git/COMMIT_EDITMSG

  create_branch_commit branch_three branch_file_three
  add_file still_committing.txt
  git commit -q -m 'Avoid fast-forward'
  GIT_DUET_ROTATE_AUTHOR=1 git duet-merge branch_three -q

  run git log -1 --format='%an <%ae>'
  assert_success 'Zubaz Shirts <z.shirts@pika.info.local>'
  [[ $(grep -o 'Signed-off-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 2 ]]
  grep 'Signed-off-by: Jane Doe <jane@hamsters.biz.local>' .git/COMMIT_EDITMSG
  grep 'Signed-off-by: Frances Bar <f.bar@hamster.info.local>' .git/COMMIT_EDITMSG
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

@test "GIT_DUET_ROTATE_AUTHOR respects GIT_DUET_SET_GIT_USER_CONFIG" {
  GIT_DUET_SET_GIT_USER_CONFIG=1 git duet -g jd fb
  run git config --global "user.email"
  assert_success 'jane@hamsters.biz.local'

  create_branch_commit branch_one branch_file_one
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'
  GIT_DUET_SET_GIT_USER_CONFIG=1 GIT_DUET_ROTATE_AUTHOR=1 git duet-merge branch_one -q
  assert_success

  run git config --global "user.name"
  assert_success 'Frances Bar'
  run git config --global "user.email"
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

@test "respects GIT_DUET_GLOBAL" {
  git duet -q -g zs jd
  git duet -q fb on

  create_branch_commit branch_one branch_file_one
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'
  GIT_DUET_GLOBAL=1 git duet-merge branch_one -q
  assert_success

  run git log -1 --format='%an <%ae>'
  assert_success 'Zubaz Shirts <z.shirts@pika.info.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
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
  git duet jd fb
  create_branch_commit branch_one branch_file_one
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'

  git config --unset-all "$GIT_DUET_CONFIG_NAMESPACE.git-author-initials"
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
  git duet -q jd fb
  create_branch_commit branch_one branch_file_one
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'

  git config --unset-all "$GIT_DUET_CONFIG_NAMESPACE.git-author-initials"
  run git duet-merge branch_one -q

  assert_failure "git-author not set"
}

@test "rejects commits with stale soloists with hook" {
  # if in CI, git-duet-pre-commit will not be in the PATH
  # exposed to git hooks
  if [ -n "$CI" ] ; then
    skip "cannot test commit hook on CI without sudo"
  fi

  git duet -q jd fb

  create_branch_commit branch_one branch_file_one

  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'

  git solo -q jd
  git duet-install-hook -q pre-commit
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

  git duet -q jd fb

  create_branch_commit branch_one branch_file_one
  add_file another_commit.txt
  git commit -q -m 'Avoid fast-forward'

  git duet -q jd fb
  git duet-install-hook -q pre-commit

  git config --unset-all "$GIT_DUET_CONFIG_NAMESPACE.mtime"

  run git duet-merge branch_one -q

  assert_failure
  assert_line "your git duet settings are stale"
}

@test "does not ammend the commit for fast-forward merges" {
  git duet -q jd fb

  create_branch_commit branch_one branch_file_one

  run git duet-merge branch_one -q
  assert_success

  run git log -1 --format='%H' master
  master_hash=$lines
  assert_success

  run git log -1 --format='%H' branch_one
  branch_hash=$lines
  assert_success

  assert_equal $branch_hash $master_hash
}

@test "does not rotate author for fast-forward merges" {
  git duet -q fb jd

  create_branch_commit branch_one branch_file_one

  GIT_DUET_ROTATE_AUTHOR=1 git duet-merge branch_one -q

  run git log -1 --format='%an <%ae>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
}

@test "handles fast-forward check if there is only one commit" {
  git duet -q fb jd

  git checkout -b branch_one

  run git duet-merge master -q
  assert_success

  run git log -1 --format='%H' master
  master_hash=$lines
  assert_success

  run git log -1 --format='%H' branch_one
  branch_hash=$lines
  assert_success

  assert_equal $branch_hash $master_hash
}
