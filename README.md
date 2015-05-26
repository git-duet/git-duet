# Git Duet

**WORK IN PROGRESS -- actively porting github.com/meatballhat/git-duet to Golang**

[![Build Status](https://travis-ci.org/jszwedko/go-git-duet.png?branch=master)](https://travis-ci.org/jszwedko/go-git-duet)

Pair harmoniously!  Working in a pair doesn't mean you've both lost your
identity.  Git Duet helps with blaming/praising by using stuff that's
already in `git` without littering your repo history with fictitous user
identities.

## Installation

See releases page for binary downloads, place in your `$PATH`.

## Usage

### Setup

Make an authors file with email domain, or if you're already using
[git pair](https://github.com/pivotal/git_scripts), just symlink your
`~/.pairs` file over to `~/.git-authors`.

``` yaml
authors:
  jd: Jane Doe; jane
  fb: Frances Bar
email:
  domain: awesometown.local
```

`git duet` will use the `git pair` YAML structure if it has to (the
difference is the top-level key being `pairs` instead of `authors`,) e.g.:

``` yaml
pairs:
  jd: Jane Doe; jane
  fb: Frances Bar
email:
  domain: awesometown.local
```

If you want your authors file to live somwhere else, just tell
Git Duet about it via the `GIT_DUET_AUTHORS_FILE` environmental
variable, e.g.:

``` bash
export GIT_DUET_AUTHORS_FILE=$HOME/.secret-squirrel/git-authors
# ...
git duet jd am
```

### Workflow stuff

Set the author and committer via `git duet`:

``` bash
git duet jd fb
```

When you're ready to commit, use `git duet-commit` or `git dci`

``` bash
git duet-commit -v [any other git options]
# or...
git dci -v [any other git options]
```

When you're done pairing, set the author back to yourself with `git solo`:

``` bash
git solo jd
```

### Global Config Support

If you're jumping between projects and don't want to think about
managing them all individually, you can operate on the global git
config:

``` bash
git solo -g jd
```

``` bash
git duet --global jd fb
```
If you do this habitually, you can set the `GIT_DUET_GLOBAL` environment
variable to `true` to always operate on the global git config:

``` bash
export GIT_DUET_GLOBAL=true
git solo jd
```

``` bash
GIT_DUET_GLOBAL=true git duet jd fb
```

You can also set it to `false` to always operate on the local config, even if
the global flag is used.

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
variable.  The template should be a valid ERB string and the variables
available are `author` which is the full first and last name value
associated with each set of initials, `initials` which are the initials
key, and `username` which is the part following `;` in the author value.

``` yaml
pairs:
  jd: Jane Doe
  fb: Frances Bar
email_template: '<%= "#{author.gsub(/ /, "-").downcase}@hamster.local" =%>'
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
email, it is important to note the order of precedence used by Git Duet:

1. Email lookup executable configured via the
   `GIT_DUET_EMAIL_LOOKUP_COMMAND` environmental variable
2. Email lookup from `email_addresses` in your configuration file
3. Custom email address from ERB template defined in `email_template` in
   your configuration file
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
\curl -Ls -o ~/scripts/rubymine-git-wrapper https://raw.github.com/modcloth/git-duet/master/scripts/rubymine-git-wrapper
chmod +x ~/bin/rubymine-git-wrapper
```

Given an install location of `~/bin/rubymine-git-wrapper` as shown
above, you would then update your RubyMine setting in
*Preferences* =&gt; *Version Control* =&gt; *Git* to set
**Path to Git executable** to the full path of
 `~/bin/rubymine-git-wrapper` (with the `~` expanded).
See issue #8 for more details.


## Differences from meatballhat/git-duet
- Running `git solo` or `git duet` with no initials outputs configuration in
  same format as when setting (env variables)
- Remove email template ERB in lieu of just using lookup command with awk/sed/etc.?

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git dci -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
