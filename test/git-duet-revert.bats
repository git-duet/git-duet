#!/usr/bin/env bats

load test_helper

@test "lists the alpha of the duet as author in the log" {
  git duet -q jd fb
  git duet-revert --no-edit HEAD
  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
}

@test "lists the omega of the duet as committer in the log" {
  git duet -q jd fb
  git duet-revert --no-edit HEAD
  run git log -1 --format='%cn <%ce>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'
}

@test "does not rotate author by default" {
  git duet -q jd fb

  git duet-revert --no-edit HEAD
  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'

  git duet-revert --no-edit HEAD
  git log -1 --format='%an <%ae>'
  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'
}

@test "respects GIT_DUET_ROTATE_AUTHOR" {
  git duet -q jd fb

  GIT_DUET_ROTATE_AUTHOR=1 git duet-revert --no-edit HEAD
  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'

  GIT_DUET_ROTATE_AUTHOR=1 git duet-revert --no-edit HEAD
  run git log -1 --format='%an <%ae>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
}

@test "respects GIT_DUET_ROTATE_AUTHOR with three contributors" {
  git duet -q jd fb zs

  GIT_DUET_ROTATE_AUTHOR=1 git duet-revert --no-edit HEAD
  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'

  GIT_DUET_ROTATE_AUTHOR=1 git duet-revert --no-edit HEAD
  run git log -1 --format='%an <%ae>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Zubaz Shirts <z.shirts@pika.info.local>'

  GIT_DUET_ROTATE_AUTHOR=1 git duet-revert --no-edit HEAD
  run git log -1 --format='%an <%ae>'
  assert_success 'Zubaz Shirts <z.shirts@pika.info.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
}


@test "GIT_DUET_ROTATE_AUTHOR updates the correct config" {
  git duet -q -g jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane@hamsters.biz.local'

  GIT_DUET_ROTATE_AUTHOR=1 git duet-revert --no-edit HEAD
  assert_success

  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'f.bar@hamster.info.local'
}

@test "does not update mtime when rotating committer" {
  git duet -q jd fb
  git config --unset-all "$GIT_DUET_CONFIG_NAMESPACE.mtime"
  GIT_DUET_ROTATE_AUTHOR=1 git duet-revert --no-edit HEAD
  assert_success
  run git config "$GIT_DUET_CONFIG_NAMESPACE.mtime"
  assert_equal 1 $status
}

@test "lists the soloist as author in the log" {
  git solo -q jd
  git duet-revert --no-edit HEAD
  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
}

@test "lists the soloist as committer in the log" {
  git solo -q jd
  git duet-revert --no-edit HEAD
  run git log -1 --format='%cn <%ce>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
}

@test "does not include Signed-off-by when soloing" {
  git solo -q jd
  git duet-revert --no-edit HEAD
  run grep 'Signed-off-by' .git/COMMIT_EDITMSG
  assert_failure ''
}

@test "rejects commits with no author" {
  run git duet-revert --no-edit HEAD
  assert_failure
}

@test "writes mtime to config" {
  git duet jd fb
  git duet-revert --no-edit HEAD
  run git config "$GIT_DUET_CONFIG_NAMESPACE.mtime"
  assert_success
}

@test "does not panic if no duet pair set" {
  run git duet-revert --no-edit HEAD
  assert_line "git-author not set"
}
