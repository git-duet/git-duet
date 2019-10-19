#!/usr/bin/env bats

load test_helper

@test "version is displayed" {
  run git duet -v
  if ! echo "$output" | grep -o -E "^[0-9]\.[0-9]\.[0-9].* \('[a-f0-9]{40}'\)$" ; then
    echo "expected '$output' to match version spec" | flunk
  fi
}

@test "requires 2 or more users" {
  run git duet jd
  assert_failure 'must specify at least two sets of initials'
}

@test "allows 3 users" {
  git duet -q jd fb zs
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-initials"
  assert_success 'jd'
}

@test "sets the git user initials" {
  git duet -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-initials"
  assert_success 'jd'
}

@test "sets the git user name" {
  git duet -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-name"
  assert_success 'Jane Doe'
}

@test "sets the git user email" {
  git duet -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane@hamsters.biz.local'
}

@test "sets the git committer initials" {
  git duet -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-initials"
  assert_success 'fb'
}

@test "caches the git committer name" {
  git duet -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-name"
  assert_success 'Frances Bar'
}

@test "caches the git committer email" {
  git duet -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-email"
  assert_success 'f.bar@hamster.info.local'
}

@test "looks up external author email" {
  GIT_DUET_EMAIL_LOOKUP_COMMAND=$GIT_DUET_TEST_LOOKUP git duet -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane_doe@lookie.me.local'
}

@test "looks up external committer email" {
  GIT_DUET_EMAIL_LOOKUP_COMMAND=$GIT_DUET_TEST_LOOKUP git duet -q jd fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-committer-email"
  assert_success 'fb9000@dalek.info.local'
}

@test "uses custom email template for author when provided" {
  local suffix=$RANDOM

  set_custom_email_template "{{with split .Name \" \"}}{{with index . 0}}{{toLower . }}{{end}}.{{with index . 1}}{{toLower . }}{{end}}{{end}}$suffix@mompopshop.local"

  git duet -q zp fb
  run git config "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success "zubaz.pants$suffix@mompopshop.local"

  clear_custom_email_template
}

@test "sets the git user email globally" {
  git duet -g -q jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane@hamsters.biz.local'
}

@test "sets the git user initials globally" {
  git duet -g -q jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-initials"
  assert_success 'jd'
}

@test "sets the git user name globally" {
  git duet -g -q jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-name"
  assert_success 'Jane Doe'
}

@test "sets the git committer email globally" {
  git duet -g -q jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-committer-name"
  assert_success 'Frances Bar'
}

@test "sets the git committer initials globally" {
  git duet -g -q jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-committer-initials"
  assert_success 'fb'
}

@test "sets the git committer name globally" {
  git duet -g -q jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-committer-email"
  assert_success 'f.bar@hamster.info.local'
}

@test "reads configuration globally" {
  git duet -g -q jd fb
  git duet fb on
  run git duet -g
  assert_success
  assert_line "GIT_AUTHOR_NAME='Jane Doe'"
  assert_line "GIT_AUTHOR_EMAIL='jane@hamsters.biz.local'"
  assert_line "GIT_COMMITTER_NAME='Frances Bar'"
  assert_line "GIT_COMMITTER_EMAIL='f.bar@hamster.info.local'"
}

@test "does not sets git user.name and user.email by default" {
  git duet -q jd fb
  run git config "user.name"
  assert_success 'Test User'
  run git config "user.email"
  assert_success 'test@example.com'
}

@test "sets git user.name and user.email if GIT_DUET_SET_GIT_USER_CONFIG" {
  GIT_DUET_SET_GIT_USER_CONFIG=1 git duet -q jd fb
  run git config "user.name"
  assert_success 'Jane Doe'
  run git config "user.email"
  assert_success 'jane@hamsters.biz.local'
}

@test "sets git user.name and user.email if GIT_DUET_CO_AUTHORED_BY" {
  # since GIT_DUET_CO_AUTHORED_BY implicitly sets GIT_DUET_SET_GIT_USER_CONFIG
  GIT_DUET_CO_AUTHORED_BY=1 git duet -q jd fb
  run git config "user.name"
  assert_success 'Jane Doe'
  run git config "user.email"
  assert_success 'jane@hamsters.biz.local'
}

@test "output is displayed" {
  run git duet jd fb
  assert_line "GIT_AUTHOR_NAME='Jane Doe'"
  assert_line "GIT_AUTHOR_EMAIL='jane@hamsters.biz.local'"
  assert_line "GIT_COMMITTER_NAME='Frances Bar'"
  assert_line "GIT_COMMITTER_EMAIL='f.bar@hamster.info.local'"
}

@test "output is not displayed when quieted" {
  run git duet -q jd fb
  assert_success ""
}

@test "prints current config" {
  git duet -q jd fb
  run git duet
  assert_line "GIT_AUTHOR_NAME='Jane Doe'"
  assert_line "GIT_AUTHOR_EMAIL='jane@hamsters.biz.local'"
  assert_line "GIT_COMMITTER_NAME='Frances Bar'"
  assert_line "GIT_COMMITTER_EMAIL='f.bar@hamster.info.local'"
}

@test "honors source when printing config" {
  git duet -q -g on jd
  git solo fb
  run git duet
  assert_line "GIT_AUTHOR_NAME='Frances Bar'"
  assert_line "GIT_AUTHOR_EMAIL='f.bar@hamster.info.local'"
  assert_line "GIT_COMMITTER_NAME='Frances Bar'"
  assert_line "GIT_COMMITTER_EMAIL='f.bar@hamster.info.local'"
}

@test "respects git root level .git-authors configuration" {
  setup_root_git_author
  mkdir new_dir
  cd new_dir

  git duet -q dj fc
  run git duet

  assert_success
  assert_line "GIT_AUTHOR_NAME='Dane Joe'"
  assert_line "GIT_AUTHOR_EMAIL='dane@bananas.biz.local'"
  assert_line "GIT_COMMITTER_NAME='Frances Car'"
  assert_line "GIT_COMMITTER_EMAIL='f.car@banana.info.local'"
}

@test "does not error when run outside of a git repository" {
  run git duet -g jd fb
  assert_success

  mkdir ${GIT_DUET_TEST_DIR}/no-repo
  cd ${GIT_DUET_TEST_DIR}/no-repo

  unset GIT_DUET_AUTHORS_FILE
  run git duet
  assert_success
  assert_line "GIT_AUTHOR_NAME='Jane Doe'"
  assert_line "GIT_AUTHOR_EMAIL='jane@hamsters.biz.local'"
  assert_line "GIT_COMMITTER_NAME='Frances Bar'"
  assert_line "GIT_COMMITTER_EMAIL='f.bar@hamster.info.local'"
}

@test "installs prepare-commit-msg hook file if GIT_DUET_CO_AUTHORED_BY" {
  GIT_DUET_CO_AUTHORED_BY=1 git duet -q jd fb
  assert_success
  [ -f .git/hooks/prepare-commit-msg ]
}

@test "without args installs the hook and sets git user.name and user.email if GIT_DUET_CO_AUTHORED_BY" {
  git duet -q jd fb
  run git config "user.name"
  assert_success 'Test User'
  run git config "user.email"
  assert_success 'test@example.com'
  [ ! -f .git/hooks/prepare-commit-msg ]

  GIT_DUET_CO_AUTHORED_BY=1 git duet -q
  run git config "user.name"
  assert_success 'Jane Doe'
  run git config "user.email"
  assert_success 'jane@hamsters.biz.local'
  [ -f .git/hooks/prepare-commit-msg ]
}

@test "writes Co-authored-by trailer for commits if GIT_DUET_CO_AUTHORED_BY" {
  GIT_DUET_CO_AUTHORED_BY=1 git duet -q jd fb
  add_file first.txt
  git commit -q -m 'Testing jd as author, fb as co-author'

  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  grep 'Co-authored-by: Frances Bar <f.bar@hamster.info.local>' .git/COMMIT_EDITMSG
  assert_success
}

@test "writes Co-authored-by trailers for multiple authors if GIT_DUET_CO_AUTHORED_BY" {
  GIT_DUET_CO_AUTHORED_BY=1 git duet -q jd fb zs
  add_file first.txt
  git commit -q -m 'Testing jd as author, fb and zs as co-authors'

  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  grep 'Co-authored-by: Frances Bar <f.bar@hamster.info.local>' .git/COMMIT_EDITMSG
  grep 'Co-authored-by: Zubaz Shirts <z.shirts@pika.info.local>' .git/COMMIT_EDITMSG
}

@test "writes Co-authored-by trailer for merge-commits if GIT_DUET_CO_AUTHORED_BY" {
  GIT_DUET_CO_AUTHORED_BY=1 git duet -q jd fb
  create_branch_commit
  git merge -q --no-ff new_branch

  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --pretty=%B
  [[ $output = *"Co-authored-by: Frances Bar <f.bar@hamster.info.local>"* ]]
}

@test "writes Co-authored-by trailer for reverts if GIT_DUET_CO_AUTHORED_BY" {
  GIT_DUET_CO_AUTHORED_BY=1 git duet -q jd fb
  git revert --no-edit HEAD

  run git log -1 --format='%an <%ae>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  grep 'Co-authored-by: Frances Bar <f.bar@hamster.info.local>' .git/COMMIT_EDITMSG
}

@test "does not write Co-authored-by trailer when rebasing if GIT_DUET_CO_AUTHORED_BY" {
  add_file first.txt
  git commit -q -m 'I get rebased'
  GIT_DUET_CO_AUTHORED_BY=1 git duet -q jd fb
  git rebase --force-rebase HEAD~1

  # rebasing modifies only the committer, but not the author(s)
  run git log -1 --format='%an <%ae>'
  assert_success 'Test User <test@example.com>'
  run git log -1 --format='%cn <%ce>'
  assert_success 'Jane Doe <jane@hamsters.biz.local>'
  run git log -1 --pretty=%B
  [[ ! $output = *"Co-authored-by:"* ]]
}

@test "does not add duplicate Co-authored-by trailers when amending a commit if GIT_DUET_CO_AUTHORED_BY" {
  GIT_DUET_CO_AUTHORED_BY=1 git duet -q jd fb
  add_file first.txt
  git commit -q -m 'I get amended'
  [[ $(grep -o 'Co-authored-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 1 ]]

  git commit -q --amend --no-edit
  [[ $(grep -o 'Co-authored-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 1 ]]
}

@test "adds Co-authored-by trailer when new co-author amends a commit if GIT_DUET_CO_AUTHORED_BY" {
  GIT_DUET_CO_AUTHORED_BY=1 git duet -q jd fb
  add_file first.txt
  git commit -q -m 'I get amended'
  [[ $(grep -o 'Co-authored-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 1 ]]

  GIT_DUET_CO_AUTHORED_BY=1 git duet -q jd zs
  git commit -q --amend --no-edit
  [[ $(grep -o 'Co-authored-by' .git/COMMIT_EDITMSG | wc -l | xargs) = 2 ]]
  grep 'Co-authored-by: Frances Bar <f.bar@hamster.info.local>' .git/COMMIT_EDITMSG
  grep 'Co-authored-by: Zubaz Shirts <z.shirts@pika.info.local>' .git/COMMIT_EDITMSG
}

@test "does not rotate author by default" {
  export GIT_DUET_CO_AUTHORED_BY=1
  git duet -q jd fb

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

@test "respects GIT_DUET_ROTATE_AUTHOR" {
  export GIT_DUET_CO_AUTHORED_BY=1
  export GIT_DUET_ROTATE_AUTHOR=1
  git duet -q jd fb

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

@test "respects GIT_DUET_ROTATE_AUTHOR with three contributors" {
  export GIT_DUET_CO_AUTHORED_BY=1
  export GIT_DUET_ROTATE_AUTHOR=1
  git duet -q jd fb zs

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

@test "GIT_DUET_ROTATE_AUTHOR updates the correct config" {
  export GIT_DUET_CO_AUTHORED_BY=1
  export GIT_DUET_ROTATE_AUTHOR=1
  git duet -q -g jd fb
  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'jane@hamsters.biz.local'

  add_file first.txt
  git commit -q -m 'Testing jd as author, fb as co-author'

  run git config --global "$GIT_DUET_CONFIG_NAMESPACE.git-author-email"
  assert_success 'f.bar@hamster.info.local'
}

@test "GIT_DUET_ROTATE_AUTHOR respects GIT_DUET_SET_GIT_USER_CONFIG" {
  export GIT_DUET_CO_AUTHORED_BY=1
  export GIT_DUET_ROTATE_AUTHOR=1
  export GIT_DUET_SET_GIT_USER_CONFIG=1
  git duet -g jd fb
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

@test "does not update mtime when rotating co-author" {
  export GIT_DUET_CO_AUTHORED_BY=1
  export GIT_DUET_ROTATE_AUTHOR=1
  git duet -q jd fb
  git config --unset-all "$GIT_DUET_CONFIG_NAMESPACE.mtime"
  add_file
  git commit -q -m 'Testing mtime not set'
  run git config "$GIT_DUET_CONFIG_NAMESPACE.mtime"
  assert_equal 1 $status
}

@test "rotates committer and adds Co-authored-by trailer for new author when amending a commit and GIT_DUET_CO_AUTHORED_BY and GIT_DUET_ROTATE_AUTHOR" {
  export GIT_DUET_CO_AUTHORED_BY=1
  export GIT_DUET_ROTATE_AUTHOR=1
  git duet -q jd fb
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

@test "--show option prints current author and committer if set" {
  git duet jd fb
  run git duet --show
  assert_line "GIT_AUTHOR_NAME='Jane Doe'"
  assert_line "GIT_AUTHOR_EMAIL='jane@hamsters.biz.local'"
  assert_line "GIT_COMMITTER_NAME='Frances Bar'"
  assert_line "GIT_COMMITTER_EMAIL='f.bar@hamster.info.local'"
}

@test "When GIT_DUET_DEFAULT_UPDATE is set, git duet with no args shows message to require initials" {
  GIT_DUET_DEFAULT_UPDATE=1 run git duet
  assert_line "must specify at least two sets of initials"
}
