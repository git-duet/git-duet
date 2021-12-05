## 0.9.0

IMPROVEMENTS:

* Support added for `darwin/arm64` for new M1 Macs

## 0.8.0

IMPROVEMENTS:

* A `--show` flag was added to `git solo` and `git duet` that can be used to
  show the currently configured authors
* A `git as` subcommand was added that can be used instead of `git solo` and
  `git duet` to modify the pairing configuration. It takes a list of initials.
  If only one set is passed, this is effectively the same as `git solo`,
  otherwise it is effectively the same as `git duet`.

BUG FIXES:

* `git solo` now clears the duet committer if no args are passed
* `git duet install-hook` no longer fails if the commit hooks already have the right
  command
* Works on MacOS Monterey now via building with a newer version of Go

## 0.7.0

IMPROVEMENTS:
* Better error messages if authors file is invalid YAML

BUG FIXES:

* Fix reading of `$GIT_DUET_SECONDS_AGO_STALE`. This value was previously ignored.
* Running `git-(solo|duet)` outside of a git repo (regression in 0.6.0)
* `$GIT_DUET_CO_AUTHORED_BY` respects `$GIT_DUET_ROTATE_AUTHOR`
* `git-duet-merge` now correctly handles fast-forward merges now by not rewriting

## 0.6.0

IMPROVEMENTS:

* Experimental support for alternative workflow added using trailers rather than setting the author/commiter
  (https://github.com/git-duet/git-duet/pull/57) via `$GIT_DUET_CO_AUTHORED_BY`. See README documentation for usage.

## 0.5.2

BUG FIXES:

* Fix Rubymine `git` wrapper script to match what Rubymine now passes
* Return an actual error when the `git-author` is not set and using the global
  git-duet configuration

## 0.5.1

BUG FIXES:

* Send `--version` to stdout

## 0.5.0

IMPROVEMENTS:

* Added a `--version` flag

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
