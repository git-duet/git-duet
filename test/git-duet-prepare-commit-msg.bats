#!/usr/bin/env bats

load test_helper

@test "appends the story ID to the commit message after git-solo" {
  git duet-install-hook -q

  git solo -q jd 201517
  add_file
  git duet-commit -q -m 'Testing formatting of commit msg for git-solo'

  run git log -1 --pretty='%b'
  assert_output '[#201517]'
}

@test "appends the story ID to the commit message after git-duet" {
  git duet-install-hook -q
  git duet -q jd fb 201519
  add_file
  git duet-commit -q -m 'Testing formatting of commit msg for git-duet'

  run git log -1 --pretty='%b'
  assert_line '[#201519]'
}

@test "does not appent the story ID to the commit message when it's already presented after git-duet" {
  git duet-install-hook -q
  git duet -q jd fb 201517
  add_file
  git duet-commit -q -m 'Testing formatting of commit msg for git-duet [#201517]'

  run git log -1 --format='%s%n%b'
  assert_line 'Testing formatting of commit msg for git-duet [#201517]'
  assert_line 'Signed-off-by: Frances Bar <f.bar@hamster.info.local>'
}

@test "does not appent the story ID to the commit message when it's already presented after git-solo" {
  git duet-install-hook -q
  git solo -q jd 201517
  add_file
  git duet-commit -q -m 'Testing formatting of commit msg for git-solo [#201517]'

  run git log -1 --format='%s%n%b'
  assert_output 'Testing formatting of commit msg for git-solo [#201517]'
}
