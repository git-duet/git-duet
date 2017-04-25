# git-duet

[![Build Status](https://travis-ci.org/git-duet/git-duet.svg?branch=master)](https://travis-ci.org/git-duet/git-duet)

Pair harmoniously!  Working in a pair doesn't mean you've both lost your
identity.  `git-duet` helps with blaming/praising by using stuff that's already
in `git` without littering your repo history with fictitous user identities. It
does so by utilizing `git`s commit committer attributes to store the identity
of the second pair.

Example:
```
$ cat <<-EOF > ~/.git-authors
authors:
  jd: Jane Doe; jane
  fb: Frances Bar
email:
  domain: awesometown.local
EOF

$ git duet jd fb
GIT_AUTHOR_NAME='Jane Doe'
GIT_AUTHOR_EMAIL='jane@awesometown.local'
GIT_COMMITTER_NAME='Frances Bar'
GIT_COMMITTER_EMAIL='f.bar@awesometown.local'

$ touch foo

$ git duet-commit -a -m 'initial commit'
[master (root-commit) ce78563] initial commit
 Author: Jane Doe <jane@awesometown.local>
 1 file changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 foo

$ git show --format=full
commit ce7856371e3e3a6d05f1b66af96f086df071e783
Author: Jane Doe <jane@awesometown.local>
Commit: Frances Bar <f.bar@awesometown.local>

    initial commit

    Signed-off-by: Frances Bar <f.bar@awesometown.local>

diff --git a/foo b/foo
new file mode 100644
index 0000000..e69de29
```

## Installation

Options:

0. See releases page for binary downloads, place in your `$PATH`.
0. Install using Homebrew from the [git-duet homebrew tap](https://github.com/git-duet/homebrew-tap)
0. Build from source: `GOVENDOREXPERIMENT=1 go get github.com/git-duet/git-duet/...`

## Usage

### Setup

Make an authors file with email domain, or if you're already using
[git pair](https://github.com/pivotal/git_scripts), just symlink your
`~/.pairs` file over to `~/.git-authors`. You can also set a repository
specific authors file by placing a `.git-authors` file at the root
of your `git` repository.

``` yaml
authors:
  jd: Jane Doe; jane
  fb: Frances Bar
email:
  domain: awesometown.local
```

`git duet` will use the `git pair` YAML structure if it has to (the
difference is the top-level key being `pairs` instead of `authors`) e.g.:

``` yaml
pairs:
  jd: Jane Doe; jane
  fb: Frances Bar
email:
  domain: awesometown.local
```

If you want your authors file to live somewhere else, just tell
`git-duet` about it via the `GIT_DUET_AUTHORS_FILE` environmental
variable, e.g.:

``` bash
export GIT_DUET_AUTHORS_FILE=$HOME/.secret-squirrel/git-authors
# ...
git duet jd am
```

### Workflow

Set two authors (pairing):

``` bash
git duet jd fb
```

Set one author (soloing):

``` bash
git solo jd
```

Committing (needed to set `--signoff` and export environment variables):

``` bash
$ git duet-commit -v [any other git options]
```

Reverting (needed to set `--signoff` and export environment variables):

``` bash
git duet-revert -v [any other git options]
```

Merging (needed to set `--signoff` and export environment variables):

``` bash
git duet-merge -v [any other git options]
```

Rebasing (resets the author/committer to the current pair):

```bash
git rebase -i --exec 'git duet-commit --amend --reset-author'
```

Suggested aliases:

```
dci = duet-commit
drv = duet-revert
dmg = duet-merge
drb = rebase -i --exec 'git duet-commit --amend --reset-author'
```

**Note:** `git-duet` only sets the configuration to use via `git duet-commit`,
`git duet-revert`, and `git duet-merge`. Using `git solo` (or `git duet`) will
not effect the configured `user.name` and `user.email`.  This allows `git
commit` to be used normally outside of `git-duet`. You can set an environment
variable, `GIT_DUET_SET_GIT_USER_CONFIG` to `1` to override this behavior and
set the `user.name` and `user.email` fields.

Another option for `git rebase`ing with `git-duet` is to use
[git-duet-rebase.sh](scripts/git-duet-rebase.sh) courtesy of @pivotaljohn. This
script uses `git filter-branch` to update the names of all of the
authors/committers to the currently set pair. It acts on your active branch
(using the passed ref as the start point).

### Global Config Support

If you're jumping between projects and don't want to think about
managing them all individually, you can operate on the global git
config:

``` bash
git solo -g jd
git duet --global jd fb
```

If you do this habitually, you can set the `GIT_DUET_GLOBAL` environment
variable to `true` to always operate on the global git config:

``` bash
export GIT_DUET_GLOBAL=true # consider adding this to your shell profile
git solo jd
```

You can also set it to `false` to always operate on the local config, even if
the global flag is used.

**Note:** This feature behaves the same as `git config` with respect to its
treatement `--global`. For example, even if you use `--global` it will read the
locally set `git-duet` author and committer (if it exists), before looking at
the global `~/.gitconfig`.

### Rotating author/committer support

Sometimes while pairing you want to share the authorship love between the
pairs. If you set `GIT_DUET_ROTATE_AUTHOR=1` it will swap the author and
committer (if there is one) on every `git duet-commit` (after the commit).

This operates on whichever config the authorship was drawn from (e.g. if the
author/committer was set in the repository git config, it will rotate these
even if `GIT_DUET_GLOBAL` is specified).

### Mobbing support

Git duet supports more than 2 people working at a time by specifying more sets
of initials:

``` bash
git duet jd fb zp
```

If you do not set `GIT_DUET_ROTATE_AUTHOR`, then git-duet will use jd and fb
as the author and committer respectively. If you have `GIT_DUET_ROTATE_AUTHOR`
set then git-duet will rotate with each commit. The first commit will have
jd as the author, and fb as the committer. The second commit will have fb
as the author and zp as the committer and so on.

*Note:* This feature uses `,` as the delimiter which will fail to parse
properly if the user's name or e-mail address contains a `,`.

### Email Configuration

By default, email addresses are constructed from the first initial and
last name ( *or* optional username after a `;`) plus email domain, e.g.
with the following authors file:

``` yaml
pairs:
  jd: Jane Doe; jane
  fb: Frances Bar
email:
  domain: eternalstench.bog.local
```

After invoking:

``` bash
git duet jd fb
```

Then the configured email addresses will show up like this:

``` bash
git config user.email
# -> jane@eternalstench.bog.local
git config duet.env.git-author-email
# -> jane@eternalstench.bog.local
git config duet.env.git-committer-email
# -> f.bar@eternalstench.bog.local
```

A custom email template may be provided via the `email_template` config
variable.  The template should be a valid Go template string (see
http://golang.org/pkg/text/template/). The object passed in has `.Name`,
`.Username`, and `.Initials`.

Additional functions available to template:
- `toLower(s)`: lowercases string
- `toUpper(s)`: uppercases string
- `split(s, d)`: splits string on delimiter
- `replace(s, old, new, n)`: replaces `old` in `s` with `new` `n` times (set `n` to `-1` to replace all)

If you need more complex logic, consider using the lookup function described
below and `awk`.

Example:

``` yaml
pairs:
  jd: Jane Doe
  fb: Frances Bar
email_template: '{{with replace .Name " " "-" -1}}{{toLower .}}{{end}}@hamster.local'
```

After invoking:

``` bash
git duet jd fb
```

Then the configured email addresses will show up like this:

``` bash
git config user.email
# -> jane-doe@hamster.local
git config duet.env.git-author-email
# -> jane-doe@hamster.local
git config duet.env.git-committer-email
# -> frances-bar@hamster.local
```

If there are any exceptions to either the default format or a provided
`email_template` config var, explicitly setting email addresses by
initials is supported.

``` yaml
pairs:
  jd: Jane Doe; jane
  fb: Frances Bar
email:
  domain: awesometown.local
email_addresses:
  jd: jane@awesome.local
```

Then Jane Doe's email will show up like this:

``` bash
git solo jd
# ...
git config user.email
# -> jane@awesome.local
```

Alternatively, if you have some other preferred way to look up email
addresses by initials, name or username, just use that instead:

``` bash
export GIT_DUET_EMAIL_LOOKUP_COMMAND="$HOME/bin/custom-ldap-thingy"
# ... do work
git duet jd fb
# ... observe emails being set via the specified executable
```

The initials, name, and username will be passed as arguments to the
lookup executable.  Anything written to standard output will be used as
the email address:

``` bash
$HOME/bin/custom-ldap-thingy 'jd' 'Jane Doe' 'jane'
# -> doej@behemoth.company.local
```

If nothing is returned on standard output, email construction falls back
to the decisions described above.

#### Order of Precedence

Since there are multiple ways to determine an author or committer's
email, it is important to note the order of precedence used by `git-duet`:

1. Email lookup executable configured via the
   `GIT_DUET_EMAIL_LOOKUP_COMMAND` environmental variable
2. Email lookup from `email_addresses` in your configuration file
3. Custom email address from Go template defined in `email_template` in
   your configuration file (see http://golang.org/pkg/text/template/)
4. The username after the `;`, followed by `@` and the configured email
   domain
5. The lower-cased first letter of the author or committer's first name,
   followed by `.` followed by the lower-cased last name of the author
or committer, followed by `@` and the configured email domain (e.g.
`f.bar@baz.local`)

### Git hook integration

If you'd like to regularly remind yourself to set the solo or duet
initials, use `git duet-pre-commit` in your pre-commit hook:

*(in $REPO_ROOT/.git/hooks/pre-commit)*

``` bash
#!/bin/bash
exec git duet-pre-commit
```

The `duet-pre-commit` command will exit with a non-zero status if the
cached author and committer settings are missing or stale.  The default
staleness cutoff is [20 minutes](http://en.wikipedia.org/wiki/Pomodoro_Technique),
but may be configured via the `GIT_DUET_SECONDS_AGO_STALE` environmental variable,
which should be an integer of seconds, e.g.:

``` bash
export GIT_DUET_SECONDS_AGO_STALE=60
# ... do work for more than a minute
git commit -v
# ... pre-commit hook fires
```

If you want to use the default hook (as shown above), install it while
in your repo like so:

``` bash
git duet-install-hook
```

Don't worry if you forgot you already had a `pre-commit` hook installed.
The `git duet-install-hook` command will refuse to overwrite it.

### RubyMine integration

In order to have the author and committer properly set when committing
via RubyMine, a git wrapper executable may be used to override any
executions of `git commit`.  Such an executable is available in the Git
Duet repository, and may be installed somewhere in your `$PATH` like so:

``` bash
curl -Ls -o ~/bin/rubymine-git-wrapper https://raw.github.com/git-duet/git-duet/master/scripts/rubymine-git-wrapper
chmod +x ~/bin/rubymine-git-wrapper
```

Given an install location of `~/bin/rubymine-git-wrapper` as shown
above, you would then update your RubyMine setting in
*Preferences* =&gt; *Version Control* =&gt; *Git* to set
**Path to Git executable** to the full path of
 `~/bin/rubymine-git-wrapper` (with the `~` expanded).
See issue #8 for more details.

## Differences from ruby [`git-duet`](http://github.com/meatballhat/git-duet)
- Running `git solo` or `git duet` with no initials outputs configuration in
  same format as when setting (env variables)
- Does not set `user.name` and `user.email` (instead only sets namespaced
  variables) so that `git commit` continues to work as normal
- Template format is now Go's `text/template`

### Developing

See [CONTRIBUTING.md](CONTRIBUTING.md).
