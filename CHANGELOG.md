## Unrleased

IMPROVEMENTS:

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
