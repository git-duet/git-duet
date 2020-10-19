#!/usr/bin/env bats

load test_helper

@test "as: version is displayed" {
  run git as -v
  if ! echo "$output" | grep -o -E "^[0-9]\.[0-9]\.[0-9].* \('[a-f0-9]{40}'\)$" ; then
    echo "expected '$output' to match version spec" | flunk
  fi
}

@test "as solo: output is displayed" {
  run git as jd
  assert_line "GIT_AUTHOR_NAME='Jane Doe'"
  assert_line "GIT_AUTHOR_EMAIL='jane@hamsters.biz.local'"
}

@test "as solo: output is not displayed when quieted" {
  git as -q jd
  assert_success ""
}

@test "as solo: caches the git user initials as author initials" {
  git as -q jd
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-initials"
  assert_success 'jd'
}

@test "as solo: caches the git user name as author name" {
  git as -q jd
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-name"
  assert_success 'Jane Doe'
}

@test "as solo: caches the git user email as author email" {
  git as -q jd
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane@hamsters.biz.local'
}

@test "as solo: builds email from id" {
  git as al
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'abe@hamster.info.local'
}

@test "as solo: builds email from name" {
  git as zp
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'z.pants@hamster.info.local'
}

@test "as solo: builds email from two names" {
  git as on
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'oscar@hamster.info.local'
}

@test "as solo: looks up external email" {
  GIT_DUET_EMAIL_LOOKUP_COMMAND=$GIT_DUET_TEST_LOOKUP git as -q jd
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane_doe@lookie.me.local'
}

@test "as solo: uses custom email template when provided" {
  local suffix=$RANDOM

  set_custom_email_template "{{with split .Name \" \"}}{{with index . 0}}{{toLower . }}{{end}}.{{with index . 1}}{{toLower . }}{{end}}{{end}}$suffix@mompopshop.local"

  git as -q zp
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success "zubaz.pants$suffix@mompopshop.local"

  clear_custom_email_template
}

@test "as solo: unsets git committer email after duet" {
  git duet -q jd fb
  git as -q jd
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-email"
  assert_success ""
}

@test "as solo: unsets git committer initials after duet" {
  git duet -q jd fb
  git as -q jd
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-initials"
  assert_success ""
}

@test "as solo: respects GIT_DUET_GLOBAL" {
  GIT_DUET_GLOBAL=1 git as jd
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane@hamsters.biz.local'
}

@test "as solo: sets the git user email globally" {
  git as -g jd
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane@hamsters.biz.local'
}

@test "as solo: sets the git user name globally" {
  git as -g -q jd
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-name"
  assert_success 'Jane Doe'
}

@test "as solo: unsets git committer email after duet globally" {
  git duet -g -q jd fb
  git as -g -q jd
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-committer-email"
  assert_success ""
}

@test "as solo: reads configuration globally" {
  git as -g -q jd
  git as fb
  run git duet -g
  assert_success
  assert_line "GIT_AUTHOR_NAME='Jane Doe'"
  assert_line "GIT_AUTHOR_EMAIL='jane@hamsters.biz.local'"
}

@test "as solo: does not sets git user.name and user.email by default" {
  git as -q jd
  run git config "user.name"
  assert_success 'Test User'
  run git config "user.email"
  assert_success 'test@example.com'
}

@test "as solo: sets git user.name and user.email if GIT_DUET_SET_GIT_USER_CONFIG" {
  GIT_DUET_SET_GIT_USER_CONFIG=1 git as -q jd
  run git config "user.name"
  assert_success 'Jane Doe'
  run git config "user.email"
  assert_success 'jane@hamsters.biz.local'
}

@test "as solo: sets git user.name and user.email if GIT_DUET_CO_AUTHORED_BY" {
  # since GIT_DUET_CO_AUTHORED_BY implicitly sets GIT_DUET_SET_GIT_USER_CONFIG
  GIT_DUET_CO_AUTHORED_BY=1 git as -q jd
  run git config "user.name"
  assert_success 'Jane Doe'
  run git config "user.email"
  assert_success 'jane@hamsters.biz.local'
}

@test "as solo: prints current config" {
  git as -q al
  run git as
  assert_line "GIT_AUTHOR_NAME='Abraham Lincoln'"
  assert_line "GIT_AUTHOR_EMAIL='abe@hamster.info.local'"
}

@test "as solo: prints error output when commands fail" {
  cd /tmp

  run git config user.name foo
  expected_output="$output"

  run git as al
  assert_failure
  echo "output $output"
  echo "expected output $expected_output"
  assert_line "$expected_output"
}

@test "as solo: respects git root level .git-authors configuration" {
  setup_root_git_author

  GIT_DUET_SET_GIT_USER_CONFIG=1 git as -q fc
  run git config "user.name"
  assert_success 'Frances Car'
  run git config "user.email"
  assert_success 'f.car@banana.info.local'
}

@test "as solo: does not error when run outside of a git repository" {
  run git as -g jd
  assert_success

  mkdir ${GIT_DUET_TEST_DIR}/no-repo
  cd ${GIT_DUET_TEST_DIR}/no-repo

  unset GIT_DUET_AUTHORS_FILE
  git as
  run git as
  assert_success
  assert_line "GIT_AUTHOR_NAME='Jane Doe'"
  assert_line "GIT_AUTHOR_EMAIL='jane@hamsters.biz.local'"
}

@test "as solo: does not write Co-authored-by trailer if GIT_DUET_CO_AUTHORED_BY is set" {
  GIT_DUET_CO_AUTHORED_BY=1 git as -q jd
  add_file first.txt
  git commit -q -m 'I do not have a co-author'
  run grep 'Co-authored-by:' .git/COMMIT_EDITMSG
  assert_failure
}

@test "as solo: --show option prints current author and committer if set" {
  git duet jd fb
  run git as --show
  assert_line "GIT_AUTHOR_NAME='Jane Doe'"
  assert_line "GIT_AUTHOR_EMAIL='jane@hamsters.biz.local'"
  assert_line "GIT_COMMITTER_NAME='Frances Bar'"
  assert_line "GIT_COMMITTER_EMAIL='f.bar@hamster.info.local'"
}

@test "as solo: When GIT_DUET_DEFAULT_UPDATE is set, git-as with no args DOES NOT remove the duet configuration" {
  git duet jd fb
  GIT_DUET_DEFAULT_UPDATE=1 git as
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success "jane@hamsters.biz.local"
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-email"
  assert_success "f.bar@hamster.info.local"
}

@test "as duet: allows 3 users" {
  git as -q jd fb zs
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-initials"
  assert_success 'jd'
}

@test "as duet: sets the git user initials" {
  git as -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-initials"
  assert_success 'jd'
}

@test "as duet: sets the git user name" {
  git as -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-name"
  assert_success 'Jane Doe'
}

@test "as duet: sets the git user email" {
  git as -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane@hamsters.biz.local'
}

@test "as duet: sets the git committer initials" {
  git as -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-initials"
  assert_success 'fb'
}

@test "as duet: caches the git committer name" {
  git as -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-name"
  assert_success 'Frances Bar'
}

@test "as duet: caches the git committer email" {
  git as -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-email"
  assert_success 'f.bar@hamster.info.local'
}

@test "as duet: looks up external author email" {
  GIT_DUET_EMAIL_LOOKUP_COMMAND=$GIT_DUET_TEST_LOOKUP git as -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane_doe@lookie.me.local'
}

@test "as duet: looks up external committer email" {
  GIT_DUET_EMAIL_LOOKUP_COMMAND=$GIT_DUET_TEST_LOOKUP git as -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-email"
  assert_success 'fb9000@dalek.info.local'
}

@test "as duet: uses custom email template for author when provided" {
  local suffix=$RANDOM

  set_custom_email_template "{{with split .Name \" \"}}{{with index . 0}}{{toLower . }}{{end}}.{{with index . 1}}{{toLower . }}{{end}}{{end}}$suffix@mompopshop.local"

  git as -q zp fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success "zubaz.pants$suffix@mompopshop.local"

  clear_custom_email_template
}

@test "as duet: sets the git user email globally" {
  git as -g -q jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane@hamsters.biz.local'
}

@test "as duet: sets the git user initials globally" {
  git as -g -q jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-initials"
  assert_success 'jd'
}

@test "as duet: sets the git user name globally" {
  git as -g -q jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-name"
  assert_success 'Jane Doe'
}

@test "as duet: sets the git committer email globally" {
  git as -g -q jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-committer-name"
  assert_success 'Frances Bar'
}

@test "as duet: sets the git committer initials globally" {
  git as -g -q jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-committer-initials"
  assert_success 'fb'
}

@test "as duet: sets the git committer name globally" {
  git as -g -q jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-committer-email"
  assert_success 'f.bar@hamster.info.local'
}

@test "as duet: reads configuration globally" {
  git as -g -q jd fb
  git as fb on
  run git as -g
  assert_success
  assert_line "GIT_AUTHOR_NAME='Jane Doe'"
  assert_line "GIT_AUTHOR_EMAIL='jane@hamsters.biz.local'"
  assert_line "GIT_COMMITTER_NAME='Frances Bar'"
  assert_line "GIT_COMMITTER_EMAIL='f.bar@hamster.info.local'"
}

@test "as duet: does not sets git user.name and user.email by default" {
  git as -q jd fb
  run git config "user.name"
  assert_success 'Test User'
  run git config "user.email"
  assert_success 'test@example.com'
}

@test "as duet: sets git user.name and user.email if GIT_DUET_SET_GIT_USER_CONFIG" {
  GIT_DUET_SET_GIT_USER_CONFIG=1 git as -q jd fb
  run git config "user.name"
  assert_success 'Jane Doe'
  run git config "user.email"
  assert_success 'jane@hamsters.biz.local'
}

@test "as duet: sets git user.name and user.email if GIT_DUET_CO_AUTHORED_BY" {
  # since GIT_DUET_CO_AUTHORED_BY implicitly sets GIT_DUET_SET_GIT_USER_CONFIG
  GIT_DUET_CO_AUTHORED_BY=1 git as -q jd fb
  run git config "user.name"
  assert_success 'Jane Doe'
  run git config "user.email"
  assert_success 'jane@hamsters.biz.local'
}

@test "as duet: output is displayed" {
  run git as jd fb
  assert_line "GIT_AUTHOR_NAME='Jane Doe'"
  assert_line "GIT_AUTHOR_EMAIL='jane@hamsters.biz.local'"
  assert_line "GIT_COMMITTER_NAME='Frances Bar'"
  assert_line "GIT_COMMITTER_EMAIL='f.bar@hamster.info.local'"
}

@test "as duet: output is not displayed when quieted" {
  run git as -q jd fb
  assert_success ""
}

@test "as duet: prints current config" {
  git as -q jd fb
  run git as
  assert_line "GIT_AUTHOR_NAME='Jane Doe'"
  assert_line "GIT_AUTHOR_EMAIL='jane@hamsters.biz.local'"
  assert_line "GIT_COMMITTER_NAME='Frances Bar'"
  assert_line "GIT_COMMITTER_EMAIL='f.bar@hamster.info.local'"
}

@test "as duet: honors source when printing config" {
  git as fb
  git as -q -g on jd
  run git as
  assert_line "GIT_AUTHOR_NAME='Frances Bar'"
  assert_line "GIT_AUTHOR_EMAIL='f.bar@hamster.info.local'"
}

@test "as duet: respects git root level .git-authors configuration" {
  setup_root_git_author
  mkdir new_dir
  cd new_dir

  git as -q dj fc
  run git as

  assert_success
  assert_line "GIT_AUTHOR_NAME='Dane Joe'"
  assert_line "GIT_AUTHOR_EMAIL='dane@bananas.biz.local'"
  assert_line "GIT_COMMITTER_NAME='Frances Car'"
  assert_line "GIT_COMMITTER_EMAIL='f.car@banana.info.local'"
}

@test "as duet: does not error when run outside of a git repository" {
  run git as -g jd fb
  assert_success

  mkdir ${GIT_DUET_TEST_DIR}/no-repo
  cd ${GIT_DUET_TEST_DIR}/no-repo

  unset GIT_DUET_AUTHORS_FILE
  run git as
  assert_success
  assert_line "GIT_AUTHOR_NAME='Jane Doe'"
  assert_line "GIT_AUTHOR_EMAIL='jane@hamsters.biz.local'"
  assert_line "GIT_COMMITTER_NAME='Frances Bar'"
  assert_line "GIT_COMMITTER_EMAIL='f.bar@hamster.info.local'"
}

@test "as duet: installs prepare-commit-msg hook file if GIT_DUET_CO_AUTHORED_BY" {
  GIT_DUET_CO_AUTHORED_BY=1 git as -q jd fb
  assert_success
  [ -f .git/hooks/prepare-commit-msg ]
}

@test "as duet: without args installs the hook and sets git user.name and user.email if GIT_DUET_CO_AUTHORED_BY" {
  git as -q jd fb
  run git config "user.name"
  assert_success 'Test User'
  run git config "user.email"
  assert_success 'test@example.com'
  [ ! -f .git/hooks/prepare-commit-msg ]

  GIT_DUET_CO_AUTHORED_BY=1 git as -q
  run git config "user.name"
  assert_success 'Jane Doe'
  run git config "user.email"
  assert_success 'jane@hamsters.biz.local'
  [ -f .git/hooks/prepare-commit-msg ]
}

@test "as duet: writes Co-authored-by trailer for commits if GIT_DUET_CO_AUTHORED_BY" {
  GIT_DUET_CO_AUTHORED_BY=1 git as -q jd fb
  add_file first.txt
  git commit -q -m 'Testing jd as author, fb as co-author'

  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  grep 'Co-authored-by: Frances Bar <f.bar@hamster.info.local>' .git/COMMIT_EDITMSG
  assert_success
}

@test "as duet: writes Co-authored-by trailers for multiple authors if GIT_DUET_CO_AUTHORED_BY" {
  GIT_DUET_CO_AUTHORED_BY=1 git as -q jd fb zs
  add_file first.txt
  git commit -q -m 'Testing jd as author, fb and zs as co-authors'

  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  grep 'Co-authored-by: Frances Bar <f.bar@hamster.info.local>' .git/COMMIT_EDITMSG
  grep 'Co-authored-by: Zubaz Shirts <z.shirts@pika.info.local>' .git/COMMIT_EDITMSG
}

@test "as duet: writes Co-authored-by trailer for merge-commits if GIT_DUET_CO_AUTHORED_BY" {
  GIT_DUET_CO_AUTHORED_BY=1 git as -q jd fb
  create_branch_commit
  git merge -q --no-ff new_branch

  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --pretty=%B
  [[ $output = *"Co-authored-by: Frances Bar <f.bar@hamster.info.local>"* ]]
}

@test "as duet: writes Co-authored-by trailer for reverts if GIT_DUET_CO_AUTHORED_BY" {
  GIT_DUET_CO_AUTHORED_BY=1 git as -q jd fb
  git revert --no-edit HEAD

  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  grep 'Co-authored-by: Frances Bar <f.bar@hamster.info.local>' .git/COMMIT_EDITMSG
}

@test "as duet: does not write Co-authored-by trailer when rebasing if GIT_DUET_CO_AUTHORED_BY" {
  git config rebase.backend apply
  add_file first.txt
  git commit -q -m 'I get rebased'
  GIT_DUET_CO_AUTHORED_BY=1 git as -q jd fb
  git rebase --force-rebase HEAD~1

  # rebasing modifies only the committer, but not the author(s)
  run git log -1 --format='%an <%ae>'
  assert_success 'Test User <test@example.com>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --pretty=%B
  [[ ! $output = *"Co-authored-by:"* ]]
}

@test "as duet: does not add duplicate Co-authored-by trailers when amending a commit if GIT_DUET_CO_AUTHORED_BY" {
  GIT_DUET_CO_AUTHORED_BY=1 git as -q jd fb
  add_file first.txt
  git commit -q -m 'I get amended'
  [[ $(grep -o 'Co-authored-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 1 ]]

  git commit -q --amend --no-edit
  [[ $(grep -o 'Co-authored-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 1 ]]
}

@test "as duet: adds Co-authored-by trailer when new co-author amends a commit if GIT_DUET_CO_AUTHORED_BY" {
  GIT_DUET_CO_AUTHORED_BY=1 git as -q jd fb
  add_file first.txt
  git commit -q -m 'I get amended'
  [[ $(grep -o 'Co-authored-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 1 ]]

  GIT_DUET_CO_AUTHORED_BY=1 git as -q jd zs
  git commit -q --amend --no-edit
  [[ $(grep -o 'Co-authored-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 2 ]]
  grep 'Co-authored-by: Frances Bar <f.bar@hamster.info.local>' .git/COMMIT_EDITMSG
  grep 'Co-authored-by: Zubaz Shirts <z.shirts@pika.info.local>' .git/COMMIT_EDITMSG
}

@test "as duet: does not rotate author by default" {
  export GIT_DUET_CO_AUTHORED_BY=1
  git as -q jd fb

  add_file first.txt
  git commit -q -m 'Testing jd as author, fb as co-author'
  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  [[ $(grep -o 'Co-authored-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 1 ]]
  grep 'Co-authored-by: Frances Bar <f.bar@hamster.info.local>' .git/COMMIT_EDITMSG


  add_file second.txt
  git commit -q -m 'Testing jd remains author, fb remains co-author'
  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  [[ $(grep -o 'Co-authored-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 1 ]]
  grep 'Co-authored-by: Frances Bar <f.bar@hamster.info.local>' .git/COMMIT_EDITMSG
}

@test "as duet: respects GIT_DUET_ROTATE_AUTHOR" {
  export GIT_DUET_CO_AUTHORED_BY=1
  export GIT_DUET_ROTATE_AUTHOR=1
  git as -q jd fb

  add_file first.txt
  git commit -q -m 'Testing jd as author, fb as co-author'
  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  [[ $(grep -o 'Co-authored-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 1 ]]
  grep 'Co-authored-by: Frances Bar <f.bar@hamster.info.local>' .git/COMMIT_EDITMSG

  add_file second.txt
  git commit -q -m 'Testing fb as author, jd as co-author'
  run git log -1 --format='%an <%ae>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'
  [[ $(grep -o 'Co-authored-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 1 ]]
  grep 'Co-authored-by: Jane Doe <jane@hamsters.biz.local>' .git/COMMIT_EDITMSG
}

@test "as duet: respects GIT_DUET_ROTATE_AUTHOR with three contributors" {
  export GIT_DUET_CO_AUTHORED_BY=1
  export GIT_DUET_ROTATE_AUTHOR=1
  git as -q jd fb zs

  add_file first.txt
  git commit -q -m 'Testing jd as author, fb and zs as co-authors'
  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  [[ $(grep -o 'Co-authored-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 2 ]]
  grep 'Co-authored-by: Frances Bar <f.bar@hamster.info.local>' .git/COMMIT_EDITMSG
  grep 'Co-authored-by: Zubaz Shirts <z.shirts@pika.info.local>' .git/COMMIT_EDITMSG

  add_file second.txt
  git commit -q -m 'Testing fb as author, jd and zs as co-authors'
  run git log -1 --format='%an <%ae>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'
  [[ $(grep -o 'Co-authored-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 2 ]]
  grep 'Co-authored-by: Zubaz Shirts <z.shirts@pika.info.local>' .git/COMMIT_EDITMSG
  grep 'Co-authored-by: Jane Doe <jane@hamsters.biz.local>' .git/COMMIT_EDITMSG

  add_file third.txt
  git commit -q -m 'Testing za as author, jd and fb as co-authors'
  run git log -1 --format='%an <%ae>'
  assert_success 'Zubaz Shirts <z.shirts@pika.info.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Zubaz Shirts <z.shirts@pika.info.local>'
  [[ $(grep -o 'Co-authored-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 2 ]]
  grep 'Co-authored-by: Frances Bar <f.bar@hamster.info.local>' .git/COMMIT_EDITMSG
  grep 'Co-authored-by: Jane Doe <jane@hamsters.biz.local>' .git/COMMIT_EDITMSG
}

@test "as duet: GIT_DUET_ROTATE_AUTHOR updates the correct config" {
  export GIT_DUET_CO_AUTHORED_BY=1
  export GIT_DUET_ROTATE_AUTHOR=1
  git as -q -g jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane@hamsters.biz.local'

  add_file first.txt
  git commit -q -m 'Testing jd as author, fb as co-author'

  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'f.bar@hamster.info.local'
}

@test "as duet: GIT_DUET_ROTATE_AUTHOR respects GIT_DUET_SET_GIT_USER_CONFIG" {
  export GIT_DUET_CO_AUTHORED_BY=1
  export GIT_DUET_ROTATE_AUTHOR=1
  export GIT_DUET_SET_GIT_USER_CONFIG=1
  git as -g jd fb
  run git config --global "user.name"
  assert_success 'Jane Doe'
  run git config --global "user.email"
  assert_success 'jane@hamsters.biz.local'

  add_file first.txt
  git commit -q -m 'Testing jd as author, fb as co-author'

  run git config --global "user.name"
  assert_success 'Frances Bar'
  run git config --global "user.email"
  assert_success 'f.bar@hamster.info.local'
}

@test "as duet: does not update mtime when rotating co-author" {
  export GIT_DUET_CO_AUTHORED_BY=1
  export GIT_DUET_ROTATE_AUTHOR=1
  git as -q jd fb
  git config --unset-all "$GIT_DUET_CONFIG_NAMESPACE.mtime"
  add_file
  git commit -q -m 'Testing mtime not set'
  run git config "$GIT_DUET_CONFIG_NAMESPACE.mtime"
  assert_equal 1 $status
}

@test "as duet: rotates committer and adds Co-authored-by trailer for new author when amending a commit and GIT_DUET_CO_AUTHORED_BY and GIT_DUET_ROTATE_AUTHOR" {
  export GIT_DUET_CO_AUTHORED_BY=1
  export GIT_DUET_ROTATE_AUTHOR=1
  git as -q jd fb
  add_file first.txt
  git commit -q -m 'I get amended'
  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  [[ $(grep -o 'Co-authored-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 1 ]]
  grep 'Co-authored-by: Frances Bar <f.bar@hamster.info.local>' .git/COMMIT_EDITMSG

  git commit -q --amend --no-edit
  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Frances Bar <f.bar@hamster.info.local>'
  [[ $(grep -o 'Co-authored-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 2 ]]
  grep 'Co-authored-by: Frances Bar <f.bar@hamster.info.local>' .git/COMMIT_EDITMSG
  grep 'Co-authored-by: Jane Doe <jane@hamsters.biz.local>' .git/COMMIT_EDITMSG
}

@test "as duet: --show option prints current author and committer if set" {
  git as jd fb
  run git as --show
  assert_line "GIT_AUTHOR_NAME='Jane Doe'"
  assert_line "GIT_AUTHOR_EMAIL='jane@hamsters.biz.local'"
  assert_line "GIT_COMMITTER_NAME='Frances Bar'"
  assert_line "GIT_COMMITTER_EMAIL='f.bar@hamster.info.local'"
}
