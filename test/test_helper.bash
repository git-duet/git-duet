export PATH=$GOBIN:$PATH

setup() {
  GIT_DUET_TEST_DIR="${BATS_TMPDIR}/git-duet"

  mkdir "$GIT_DUET_TEST_DIR"

  export GIT_DUET_CONFIG_NAMESPACE='foo.bar'
  export GIT_DUET_AUTHORS_FILE="${GIT_DUET_TEST_DIR}/.git-authors"
  export GIT_DUET_TEST_LOOKUP="${GIT_DUET_TEST_DIR}/email-lookup"
  export GIT_DUET_TEST_REPO="${GIT_DUET_TEST_DIR}/repo"

  cat > "$GIT_DUET_AUTHORS_FILE" <<EOF
pairs:
  jd: Jane Doe
  fb: Frances Bar
  al: Abraham Lincoln; abe
  zp: Zubaz Pants

email:
  domain: hamster.info.local

email_addresses:
  jd: jane@hamsters.biz.local
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
}

teardown() {
  rm -rf "$GIT_DUET_TEST_DIR"
}

add_file() {
  touch file.txt
  git add file.txt
}

set_custom_email_template() {
  clear_custom_email_template
  echo "email_template: $1" >> "$GIT_DUET_AUTHORS_FILE"
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
