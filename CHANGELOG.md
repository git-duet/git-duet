## 0.4.0

IMPROVEMENTS:

* You can now set `GIT_DUET_SET_GIT_USER_CONFIG` to `1` to change the behavior
  of `git (solo|duet)` to also set `user.name` and `user.email` to allow for
  the use of normal `git` commands that look for these fields. Note that the
  `committer` will not be set when `git duet`ing unless you use the `git
  duet-*` wrappers.
* `git-duet-merge` was added to correctly add the `--signoff` during merges
* Add support for "mobbing" (more than 2 people pairing). This is supported by
  allowing the specification of 3 or more initials whereby after each commit
  the active pair is rotated to spread ownership evenly (requires
  `$GIT_DUET_ROTATE_AUTHOR` to be set).
* `git-duet-(commit|merge|revert)` now respect `GIT_DUET_GLOBAL` in that, if it
  is set, they will only pull the `git-duet` configuration from the global git
  config rather than looking at the repo config first

BUG FIXES:

* `git-duet` and `git-solo` now correctly respect `GIT_DUET_GLOBAL` and `-g`
  when displaying configuration

## 0.3.1

BUG FIXES:

* Build using Golang 1.7.1 to fix issues with running on Mac OSX Sierra

## 0.3.0

IMPROVEMENTS:

* `git-duet-revert` is introduced to allow you to also set the committer when reverting

BUG FIXES:

* `git-duet` did not support `~/.git-authors` files where the root key was
  `pairs:` when it was not the first line

## 0.2.0

IMPROVEMENTS:

* `git-duet-commit` now supports `GIT_DUET_ROTATE_AUTHOR` to rotate the
  committer and author after each commit

BUG FIXES:

* `git-duet-commit` prints error when author is not set rather than `panic`ing

## 0.1.0

Initial release
