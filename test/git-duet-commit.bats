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

@test "writes Signed-off-by trailer for the commits" {
  git duet -q jd fb
  add_file
  git duet-commit -q -m 'Testing jd as author, fb as committer'

  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  grep 'Signed-off-by: Frances Bar <f.bar@hamster.info.local>' .git/COMMIT_EDITMSG
}

@test "does not allow multiple committers by default" {
  git duet -q jd fb zs
  add_file
  git duet-commit -q -m 'Testing zs does not appear as a committer'

  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  [[ $(grep -o 'Signed-off-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 1 ]]
  grep 'Signed-off-by: Frances Bar <f.bar@hamster.info.local>' .git/COMMIT_EDITMSG
}

@test "allow multiple committers if GIT_DUET_ALLOW_MULTIPLE_COMMITTERS" {
  export GIT_DUET_ALLOW_MULTIPLE_COMMITTERS=1
  git duet -q jd fb zs
  add_file
  git duet-commit -q -m 'Testing jd as author, fb and zs as committers'

  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  [[ $(grep -o 'Signed-off-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 2 ]]
  grep 'Signed-off-by: Frances Bar <f.bar@hamster.info.local>' .git/COMMIT_EDITMSG
  grep 'Signed-off-by: Zubaz Shirts <z.shirts@pika.info.local>' .git/COMMIT_EDITMSG
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

@test "respects GIT_DUET_ROTATE_AUTHOR with three contributors" {
  git duet -q jd fb zs

  add_file first.txt
  GIT_DUET_ROTATE_AUTHOR=1 git duet-commit -q -m 'Testing jd as author, fb as committer'
  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'

  add_file second.txt
  GIT_DUET_ROTATE_AUTHOR=1 git duet-commit -q -m 'Testing fb as author, zs as committer'
  run git log -1 --format='%an <%ae>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Zubaz Shirts <z.shirts@pika.info.local>'

  add_file third.txt
  GIT_DUET_ROTATE_AUTHOR=1 git duet-commit -q -m 'Testing zs as author, jd as committer'
  run git log -1 --format='%an <%ae>'
  assert_success 'Zubaz Shirts <z.shirts@pika.info.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
}

@test "respects GIT_DUET_ROTATE_AUTHOR with three contributors and GIT_DUET_ALLOW_MULTIPLE_COMMITTERS" {
  export GIT_DUET_ALLOW_MULTIPLE_COMMITTERS=1
  git duet -q jd fb zs

  add_file first.txt
  GIT_DUET_ROTATE_AUTHOR=1 git duet-commit -m 'Testing jd as author, fb and zs as committers'
  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  [[ $(grep -o 'Signed-off-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 2 ]]
  grep 'Signed-off-by: Frances Bar <f.bar@hamster.info.local>' .git/COMMIT_EDITMSG
  grep 'Signed-off-by: Zubaz Shirts <z.shirts@pika.info.local>' .git/COMMIT_EDITMSG

  add_file second.txt
  GIT_DUET_ROTATE_AUTHOR=1 git duet-commit -q -m 'Testing fb as author, zs and jd as committers'
  run git log -1 --format='%an <%ae>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'
  [[ $(grep -o 'Signed-off-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 2 ]]
  grep 'Signed-off-by: Zubaz Shirts <z.shirts@pika.info.local>' .git/COMMIT_EDITMSG
  grep 'Signed-off-by: Jane Doe <jane@hamsters.biz.local>' .git/COMMIT_EDITMSG

  add_file third.txt
  GIT_DUET_ROTATE_AUTHOR=1 git duet-commit -q -m 'Testing zs as author, jd and fb as committers'
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

  add_file first.txt
  GIT_DUET_ROTATE_AUTHOR=1 git duet-commit -q -m 'Testing jd as author, fb as committer'
  assert_success

  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'f.bar@hamster.info.local'
}

@test "GIT_DUET_ROTATE_AUTHOR respects GIT_DUET_SET_GIT_USER_CONFIG" {
  GIT_DUET_SET_GIT_USER_CONFIG=1 git duet -g jd fb
  run git config --global "user.email"
  assert_success 'jane@hamsters.biz.local'

  add_file first.txt
  GIT_DUET_SET_GIT_USER_CONFIG=1 GIT_DUET_ROTATE_AUTHOR=1 git duet-commit -q -m 'Testing jd as author, fb as committer'
  assert_success

  run git config --global "user.name"
  assert_success 'Frances Bar'
  run git config --global "user.email"
  assert_success 'f.bar@hamster.info.local'
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

@test "respects GIT_DUET_GLOBAL" {
  git duet -q -g zs jd
  git duet -q jd fb

  add_file first.txt
  GIT_DUET_GLOBAL=1 git duet-commit -q -m 'Testing zs as author, jd as committer'
  assert_success

  run git log -1 --format='%an <%ae>'
  assert_success 'Zubaz Shirts <z.shirts@pika.info.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
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
  git duet-install-hook -q pre-commit
  git config "$GIT_DUET_CONFIG_NAMESPACE.mtime" "$(( $(date +%s) - 10))"
  add_file
  export GIT_DUET_SECONDS_AGO_STALE=9
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
  git duet-install-hook -q pre-commit
  git config "$GIT_DUET_CONFIG_NAMESPACE.mtime" "$(( $(date +%s) - 10))"
  add_file
  export GIT_DUET_SECONDS_AGO_STALE=9
  run git duet-commit -q -m 'Testing stale hook fire'

  assert_failure
  assert_line "your git duet settings are stale"
}
