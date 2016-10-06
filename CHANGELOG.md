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
