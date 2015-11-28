#!/usr/bin/env bats

load test_helper

@test "writes the hook to thfe pre-commit hook file" {
  run git duet-install-hook -q
  assert_success
  [ -f .git/hooks/pre-commit ]
}

@test "makes the pre-commit hook executable" {
  run git duet-install-hook -q
  assert_success
  [ -x .git/hooks/pre-commit ]
}

@test "does not overwrite existing pre-commit file" {
  touch .git/hooks/pre-commit
  run git duet-install-hook -q
  assert_failure
}

@test "writes the hook to thfe prepare-commit-msg hook file" {
  run git duet-install-hook -q
  assert_success
  [ -f .git/hooks/prepare-commit-msg ]
}

@test "makes the prepare-commit-msg hook executable" {
  run git duet-install-hook -q
  assert_success
  [ -x .git/hooks/prepare-commit-msg ]
}

@test "does not overwrite existing prepare-commit-msg file" {
  touch .git/hooks/prepare-commit-msg
  run git duet-install-hook -q
  assert_failure
}
