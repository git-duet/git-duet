package duet

import (
	"bytes"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"
)

// This wacky delimiter is here so that the git author
// bash prompt looks correct when mobbing.
const delim = ", +"

type scope int

// Default uses the default search order and writes to the local config
// Local reads and writes from the local git config
// Global reads and writes from the user git config
const (
	Default scope = iota
	Local
	Global
)

// GitConfig provides methods for interacting with git config
// If scope is Global, interacts with user git config (~/.gitconfig)
// If scope is Local, interacts with repo config
// If scope is Default 'SetXXX' operates on repo config and 'GetXXX' looks in
// repo then global (similar to `git config`)
// Namespace determines the section under which configuration will be stored
// SetUserConfig determines whether user.name and user.email are set in
// addition to the git-duet namespaced configuration for the author
type GitConfig struct {
	Namespace string
	Scope     scope

	SetUserConfig bool
}

// GetAuthorConfig returns the config source for git author information.
func GetAuthorConfig(namespace string, setUserConfig bool) (config *GitConfig, err error) {
	configs := []*GitConfig{
		{Namespace: namespace, SetUserConfig: setUserConfig, Scope: Local},
		{Namespace: namespace, SetUserConfig: setUserConfig, Scope: Global},
	}

	for _, config := range configs {
		author, err := config.GetAuthor()
		if err != nil {
			return nil, err
		}
		if author != nil {
			return config, nil
		}
	}

	return nil, errors.New("git-author not set")
}

// ClearCommitter removes committer name/email from config
func (gc *GitConfig) ClearCommitter() (err error) {
	if err = gc.setKey("git-committer-initials", ""); err != nil {
		return err
	}

	if err = gc.setKey("git-committer-name", ""); err != nil {
		return err
	}

	if err = gc.setKey("git-committer-email", ""); err != nil {
		return err
	}
	if err = gc.updateMtime(); err != nil {
		return err
	}
	return nil
}

// ClearAuthor removes duet author name/email from config
func (gc *GitConfig) ClearAuthor() (err error) {
	if err = gc.unsetKey("git-author-initials"); err != nil {
		return err
	}

	if err = gc.unsetKey("git-author-name"); err != nil {
		return err
	}

	if err = gc.unsetKey("git-author-email"); err != nil {
		return err
	}
	if err = gc.updateMtime(); err != nil {
		return err
	}
	return nil
}


// SetAuthor sets the configuration for author name and email
func (gc *GitConfig) SetAuthor(author *Pair) (err error) {
	if err = gc.setAuthor(author); err != nil {
		return err
	}
	if err = gc.updateMtime(); err != nil {
		return err
	}
	return nil
}

// SetCommitters sets the configuration for committers names and emails
func (gc *GitConfig) SetCommitters(committers ...*Pair) (err error) {
	if err = gc.setCommitters(committers); err != nil {
		return err
	}
	if err = gc.updateMtime(); err != nil {
		return err
	}
	return nil
}

// RotateAuthor flips the committer and author if committer is set
func (gc *GitConfig) RotateAuthor() (err error) {
	gitConfig := gc
	if gitConfig.Scope == Default {
		// find source of configuration
		if gitConfig, err = GetAuthorConfig(gc.Namespace, gc.SetUserConfig); err != nil {
			return err
		}
	}

	var author *Pair
	var committers []*Pair

	if author, err = gc.GetAuthor(); err != nil {
		return err
	}
	if committers, err = gc.GetCommitters(); err != nil {
		return err
	}

	if committers != nil && len(committers) > 0 {
		if err = gitConfig.setAuthor(committers[0]); err != nil {
			return err
		}

		committers = append(committers, author)
		if err = gitConfig.setCommitters(committers[1:]); err != nil {
			return err
		}
	}

	return nil
}

func (gc *GitConfig) setAuthor(author *Pair) (err error) {
	if gc.SetUserConfig {
		if err = gc.setUnnamespacedKey("user.name", author.Name); err != nil {
			return err
		}
		if err = gc.setUnnamespacedKey("user.email", author.Email); err != nil {
			return err
		}
	}
	if err = gc.setKey("git-author-initials", author.Initials); err != nil {
		return err
	}
	if err = gc.setKey("git-author-initials", author.Initials); err != nil {
		return err
	}
	if err = gc.setKey("git-author-name", author.Name); err != nil {
		return err
	}
	if err = gc.setKey("git-author-email", author.Email); err != nil {
		return err
	}
	return nil
}

func (gc *GitConfig) setCommitters(committers []*Pair) (err error) {
	var listOfInitials, listOfNames, listOfEmails []string
	for _, p := range committers {
		listOfInitials = append(listOfInitials, p.Initials)
		listOfNames = append(listOfNames, p.Name)
		listOfEmails = append(listOfEmails, p.Email)
	}

	if err = gc.setKey("git-committer-initials", strings.Join(listOfInitials, delim)); err != nil {
		return err
	}

	if err = gc.setKey("git-committer-name", strings.Join(listOfNames, delim)); err != nil {
		return err
	}

	if err = gc.setKey("git-committer-email", strings.Join(listOfEmails, delim)); err != nil {
		return err
	}

	return nil
}

// GetAuthor returns the currently configured author (nil if none)
func (gc *GitConfig) GetAuthor() (pair *Pair, err error) {
	initials, err := gc.getKey("git-author-initials")
	if err != nil {
		return nil, err
	}

	name, err := gc.getKey("git-author-name")
	if err != nil {
		return nil, err
	}

	email, err := gc.getKey("git-author-email")
	if err != nil {
		return nil, err
	}

	if name == "" || initials == "" || email == "" {
		return nil, nil
	}

	return &Pair{
		Initials: initials,
		Name:     name,
		Email:    email,
	}, nil
}

// GetCommitters returns the currently configured committers (nil if none)
func (gc *GitConfig) GetCommitters() (pairs []*Pair, err error) {
	initials, err := gc.getKey("git-committer-initials")
	if err != nil {
		return nil, err
	}
	names, err := gc.getKey("git-committer-name")
	if err != nil {
		return nil, err
	}

	emails, err := gc.getKey("git-committer-email")
	if err != nil {
		return nil, err
	}

	if initials == "" || names == "" || emails == "" {
		return nil, nil
	}

	listOfInitials := strings.Split(initials, delim)
	listOfNames := strings.Split(names, delim)
	listOfEmails := strings.Split(emails, delim)
	for i, n := range listOfInitials {
		p := &Pair{
			Initials: n,
			Name:     listOfNames[i],
			Email:    listOfEmails[i],
		}
		pairs = append(pairs, p)
	}

	return pairs, nil
}

// GetMtime returns the last time the author/committer was written
// Returns zero Time if key is missing
func (gc *GitConfig) GetMtime() (mtime time.Time, err error) {
	mtimeString, err := gc.getKey("mtime")
	if err != nil {
		return time.Time{}, err
	}

	if mtimeString == "" {
		return time.Time{}, nil
	}

	mtimeUnix, err := strconv.ParseInt(mtimeString, 10, 64)
	if err != nil {
		return time.Time{}, err
	}

	return time.Unix(mtimeUnix, 0), nil
}

func (gc *GitConfig) GetInitTemplateDir() (templateDir string, err error) {
	templateDir, err = gc.getUnnamespacedKey("init.templatedir")
	if err != nil {
		return "", err
	}
	return templateDir, err
}

func (gc *GitConfig) SetInitTemplateDir(path string) (err error) {
	if err = gc.setUnnamespacedKey("init.templatedir", path); err != nil {
		return err
	}
	return nil
}

func (gc *GitConfig) getKey(key string) (value string, err error) {
	output := new(bytes.Buffer)
	cmd := gc.configCommand(fmt.Sprintf("%s.%s", gc.Namespace, key))
	cmd.Stdout = output

	err = newIgnorableCommand(cmd, 1).Run()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(output.String()), nil
}

func (gc *GitConfig) getUnnamespacedKey(key string) (value string, err error) {
	output := new(bytes.Buffer)
	cmd := gc.configCommand(key)
	cmd.Stdout = output

	err = newIgnorableCommand(cmd, 1).Run()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(output.String()), nil
}

func (gc *GitConfig) unsetKey(key string) (err error) {
	if err = newIgnorableCommand(
		gc.configCommand("--unset-all", fmt.Sprintf("%s.%s", gc.Namespace, key)),
		5).Run(); err != nil {
		return err
	}

	return nil
}

func (gc *GitConfig) setUnnamespacedKey(key, value string) (err error) {
	if err = gc.configCommand(key, value).Run(); err != nil {
		return err
	}

	return nil
}

func (gc *GitConfig) setKey(key, value string) (err error) {
	if err = gc.configCommand(fmt.Sprintf("%s.%s", gc.Namespace, key), value).Run(); err != nil {
		return err
	}

	return nil
}

func (gc *GitConfig) updateMtime() (err error) {
	if err = gc.configCommand(
		fmt.Sprintf("%s.%s", gc.Namespace, "mtime"),
		strconv.FormatInt(time.Now().Unix(), 10)).Run(); err != nil {
		return err
	}
	return nil
}

func (gc *GitConfig) configCommand(args ...string) *exec.Cmd {
	config := []string{"config"}
	switch gc.Scope {
	case Global:
		config = append(config, "--global")
	case Local:
		config = append(config, "--local")
	}
	config = append(config, args...)
	cmd := exec.Command("git", config...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd
}
