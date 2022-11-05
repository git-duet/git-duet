# git-duet

[![Build Status](https://travis-ci.com/git-duet/git-duet.svg?branch=master)](https://travis-ci.com/git-duet/git-duet)

Pair harmoniously!  Working in a pair doesn't mean you've both lost your
identity.  `git-duet` helps with blaming/praising by using stuff that's already
in `git` without littering your repo history with fictitious user identities. It
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

1. See releases page for binary downloads, place in your `$PATH`.
1. Install using Homebrew from the [git-duet homebrew tap](https://github.com/git-duet/homebrew-tap) (`brew install git-duet/tap/git-duet`)
1. Build from source: `go install github.com/git-duet/git-duet/...@latest`.
   This will put the binaries in `$GOBIN`, if set, or `$GOPATH/bin` (see `go
   help install` for more details).

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

Set arbitrary number of authors:

```bash
git as jd # works
git as jd fb rb # also works
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

Rebasing (resets the committer to the committer of the current pair):

```bash
git rebase -i --exec 'git duet-commit --amend'
```

Suggested aliases:

```
dci = duet-commit
drv = duet-revert
dmg = duet-merge
drb = rebase -i --exec 'git duet-commit --amend'
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

### "Co-authored-by" trailer support

:warning: If you use `git commit -v` with `git < 2.14.0` you'll find that the `Co-authored-by` trailer is mistakenly
added after the verbose commit output. Please upgrade `git` if you encounter this issue.

Set the environment variable `GIT_DUET_CO_AUTHORED_BY` to `1` if you want
to have a "Co-authored-by" trailer for each co-author in your commit message
rather than having a "Signed-off-by" trailer for the committer.

If `GIT_DUET_CO_AUTHORED_BY` is set, `git duet` will install a prepare-commit-msg
hook file into the local repository by default. If, in addition, `GIT_DUET_GLOBAL` is set,
`git-duet` will instead install the prepare-commit-msg hook file into `git config --global init.templatedir`.
If the value `git config --global init.templatedir` is not set, `git-duet` will set it
to `$HOME/.git-template`.

`GIT_DUET_CO_AUTHORED_BY` implicitly sets `GIT_DUET_SET_GIT_USER_CONFIG`
so that `git duet` and `git solo` set the author for normal git commands.

The common workflow is as follows:
- run `git duet` (which will install the prepare-commit-msg hook)
- if you have `GIT_DUET_GLOBAL` set, run `git init` once in existing repos
so that the hook file gets copied from the `init.templatedir`
- thereafter, use the normal git commands (i.e. `git commit`, `git merge` rather than
the git-duet-subcommands `git duet-commit`, `git duet-merge`)
- the prepare-commit-msg hook will append a `Co-authored-by` trailer for each co-author

If `GIT_DUET_ROTATE_AUTHOR` is set in addition to `GIT_DUET_CO_AUTHORED_BY`, `git-duet` will install a post-commit hook file
which will swap author and co-author after every commit.

When amending a commit and the co-author has changed, a new `Co-authored-by` trailer will get appended for
that co-author. In order to avoid duplicate `Co-authored-by` trailers (i.e. trailers with the same co-author),
set `git config [--global] trailer.ifexists addIfDifferent` to  override the default value `addIfDifferentNeighbor`.

If you want to opt out of this feature, unsetting `GIT_DUET_CO_AUTHORED_BY` is not sufficient.
You also need to manually delete the prepare-commit-msg (and post-commit) hook file in your repo.

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
(*Note:* This feature uses `,` as the delimiter which will fail to parse
properly if the user's name or e-mail address contains a `,`.)

Additionally, if you set `GIT_DUET_ALLOW_MULTIPLE_COMMITTERS`, then git-duet
will add a sign-off trailer in the commit message for every committer that
is specified after the author:

Example:
```
$ git show --format=full
commit ce7856371e3e3a6d05f1b66af96f086df071e783
Author: Jane Doe <jane@awesometown.local>
Commit: Frances Bar <f.bar@awesometown.local>

    initial commit

    Signed-off-by: Frances Bar <f.bar@awesometown.local>
    Signed-off-by: Zubaz Shirts <z.shirts@pika.info.local>

diff --git a/foo b/foo
new file mode 100644
index 0000000..e69de29
```

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
git duet-install-hook pre-commit
```

Don't worry if you forgot you already had a `pre-commit` hook installed.
The `git duet-install-hook pre-commit` command will refuse to overwrite it.

### JetBrains IDE integration

In order to have the author and committer properly set when committing
via JetBrains IDEs (RubyMine, Intellij, WebStorm, etc.), a git wrapper executable may be used to override any
executions of `git commit`.  Such an executable is available in the Git
Duet repository, and may be installed somewhere in your `$PATH` like so:

``` bash
curl -Ls -o ~/bin/jetbrains-git-wrapper https://raw.github.com/git-duet/git-duet/master/scripts/jetbrains-git-wrapper
chmod +x ~/bin/jetbrains-git-wrapper
```

Given an install location of `~/bin/jetbrains-git-wrapper` as shown
above, you would then update your JetBrains IDE setting in
*Preferences* =&gt; *Version Control* =&gt; *Git* to set
**Path to Git executable** to the full path of
 `~/bin/jetbrains-git-wrapper` (with the `~` expanded).
See issue #8 for more details.

### VSCode extention

[git-duet for VSCode](https://marketplace.visualstudio.com/items?itemName=PhilAlsford.git-duet-vscode), has been created by a member of the comunity. Please see the README for instructions/limitations. Please direct any issues to the extentions [GitHub repo](https://github.com/philals/git-duet-vscode). 

### Incompatible future updates
When adding incompatible changes to `git-duet`, its major version will be raised. 

However, you can try such future changes before updating the major version by setting the environment variable `GIT_DUET_DEFAULT_UPDATE`
- `git solo` without arguments removes the duet configuration. 
- `git duet` without arguments indicates that you must specify two or more initials.

## Differences from ruby [`git-duet`](http://github.com/meatballhat/git-duet)
- Running `git solo` or `git duet` with no initials outputs configuration in
  same format as when setting (env variables)
- Does not set `user.name` and `user.email` (instead only sets namespaced
  variables) so that `git commit` continues to work as normal
- Template format is now Go's `text/template`

### Developing

See [CONTRIBUTING.md](CONTRIBUTING.md).
