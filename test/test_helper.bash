setup() {
  GIT_DUET_TEST_DIR="${BATS_TMPDIR}/git-duet"

  mkdir "$GIT_DUET_TEST_DIR"

  unset GIT_DUET_GLOBAL
  unset GIT_DUET_ROTATE_AUTHOR
  unset GIT_DUET_SET_GIT_USER_CONFIG
  unset GIT_DUET_CO_AUTHORED_BY
  git config --global --unset init.templatedir || true

  export GIT_DUET_CONFIG_NAMESPACE='foo.bar'
  export GIT_DUET_AUTHORS_FILE="${GIT_DUET_TEST_DIR}/.git-authors"
  export GIT_DUET_TEST_LOOKUP="${GIT_DUET_TEST_DIR}/email-lookup"
  export GIT_DUET_TEST_REPO="${GIT_DUET_TEST_DIR}/repo"

  cat > "$GIT_DUET_AUTHORS_FILE" <<EOF
---
pairs:
  jd: Jane Doe
  fb: Frances Bar
  al: Abraham Lincoln; abe
  on: Oscar
  zp: Zubaz Pants
  zs: Zubaz Shirts

email:
  domain: hamster.info.local

email_addresses:
  jd: jane@hamsters.biz.local
  fb: f.bar@hamster.info.local
  zs: z.shirts@pika.info.local
EOF

  cat > "$GIT_DUET_TEST_LOOKUP" <<EOF
#!/usr/bin/env ruby
addr = {
  'jd' => 'jane_doe@lookie.me.local',
  'fb' => 'fb9000@dalek.info.local'
}[ARGV.first]
puts addr
EOF
  chmod +x "$GIT_DUET_TEST_LOOKUP"
  git init -q "$GIT_DUET_TEST_REPO"
  cd "$GIT_DUET_TEST_REPO"
  touch foo
  git add foo
  git config user.name 'Test User'
  git config user.email 'test@example.com'
  git commit -m 'test commit for reverting'
}

teardown() {
  git config --global --remove-section $GIT_DUET_CONFIG_NAMESPACE || true
  git config --global --unset init.templatedir || true
  rm -rf "$GIT_DUET_TEST_DIR"
}

add_file() {
  if [ $# -eq 0 ]; then
    touch file.txt
    git add file.txt
  else
    touch $1
    git add $1
  fi
}

create_branch_commit() {
  if [ $# -eq 0 ]; then
    git checkout -b new_branch
  else
    git checkout -b $1
  fi

  if [ $# -lt 2 ]; then
    add_file branch_file.txt
  else
    add_file $2
  fi

  git commit -q -m 'Adding a branch commit'
  git checkout master
}

setup_root_git_author() {
  unset GIT_DUET_AUTHORS_FILE
  cat > ".git-authors" <<EOF
---
authors:
  dj: Dane Joe
  fc: Frances Car

email:
  domain: banana.info.local

email_addresses:
  dj: dane@bananas.biz.local
  fc: f.car@banana.info.local
EOF
}

assert_head_is_merge () {
    msha=$(git rev-list --merges HEAD~1..HEAD)
    [ -z "$msha" ] && return 1
    return 0
}

set_custom_email_template() {
  clear_custom_email_template
  echo "email_template: '$1'" >> "$GIT_DUET_AUTHORS_FILE"
}

clear_custom_email_template() {
  cat "$GIT_DUET_AUTHORS_FILE" | grep -v email_template > "$GIT_DUET_AUTHORS_FILE.bak"
  mv "$GIT_DUET_AUTHORS_FILE.bak" "$GIT_DUET_AUTHORS_FILE"
}

flunk() {
  { if [ "$#" -eq 0 ]; then cat -
    else echo "$@"
    fi
  } >&2
  return 1
}

assert_success() {
  if [ "$status" -ne 0 ]; then
    flunk "command failed with exit status $status"
  elif [ "$#" -gt 0 ]; then
    assert_output "$1"
  fi
}

assert_failure() {
  if [ "$status" -eq 0 ]; then
    flunk "expected failed exit status"
  elif [ "$#" -gt 0 ]; then
    assert_output "$1"
  fi
}

assert_equal() {
  if [ "$1" != "$2" ]; then
    { echo "expected: $1"
      echo "actual:   $2"
    } | flunk
  fi
}

assert_output() {
  local expected
  if [ $# -eq 0 ]; then expected="$(cat -)"
  else expected="$1"
  fi
  assert_equal "$expected" "$output"
}

assert_line() {
  if [ "$1" -ge 0 ] 2>/dev/null; then
    assert_equal "$2" "${lines[$1]}"
  else
    local line
    for line in "${lines[@]}"; do
      if [ "$line" = "$1" ]; then return 0; fi
    done
    flunk "expected line \`$1'"
  fi
}

refute_line() {
  if [ "$1" -ge 0 ] 2>/dev/null; then
    local num_lines="${#lines[@]}"
    if [ "$1" -lt "$num_lines" ]; then
      flunk "output has $num_lines lines"
    fi
  else
    local line
    for line in "${lines[@]}"; do
      if [ "$line" = "$1" ]; then
        flunk "expected to not find line \`$line'"
      fi
    done
  fi
}
