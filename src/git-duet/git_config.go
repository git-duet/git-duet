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
type GitConfig struct {
	Namespace string
	Scope     scope
}

// GetAuthorConfig returns the config source for git author information.
func GetAuthorConfig(namespace string) (config *GitConfig, err error) {
	configs := []*GitConfig{
		&GitConfig{Namespace: namespace, Scope: Local},
		&GitConfig{Namespace: namespace, Scope: Global},
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
	if err = gc.unsetKey("git-committer-name"); err != nil {
		return err
	}
	if err = gc.unsetKey("git-committer-email"); err != nil {
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

// SetCommitter sets the configuration for committer name and email
func (gc *GitConfig) SetCommitter(committer *Pair) (err error) {
	if err = gc.setCommitter(committer); err != nil {
		return err
	}
	if err = gc.updateMtime(); err != nil {
		return err
	}
	return nil
}

// RotateAuthor flips the committer and author if committer is set
func (gc *GitConfig) RotateAuthor() (err error) {
	var author, committer *Pair
	if author, err = gc.GetAuthor(); err != nil {
		return err
	}
	if committer, err = gc.GetCommitter(); err != nil {
		return err
	}

	if committer != nil {
		if err = gc.setAuthor(committer); err != nil {
			return err
		}
		if err = gc.setCommitter(author); err != nil {
			return err
		}
	}

	return nil
}

func (gc *GitConfig) setAuthor(author *Pair) (err error) {
	if err = gc.setKey("git-author-name", author.Name); err != nil {
		return err
	}
	if err = gc.setKey("git-author-email", author.Email); err != nil {
		return err
	}
	return nil
}

func (gc *GitConfig) setCommitter(committer *Pair) (err error) {
	if err = gc.setKey("git-committer-name", committer.Name); err != nil {
		return err
	}
	if err = gc.setKey("git-committer-email", committer.Email); err != nil {
		return err
	}
	return nil
}

// GetAuthor returns the currently configured author (nil if none)
func (gc *GitConfig) GetAuthor() (pair *Pair, err error) {
	name, err := gc.getKey("git-author-name")
	if err != nil {
		return nil, err
	}

	email, err := gc.getKey("git-author-email")
	if err != nil {
		return nil, err
	}

	if name == "" || email == "" {
		return nil, nil
	}

	return &Pair{
		Name:  name,
		Email: email,
	}, nil
}

// GetCommitter returns the currently configured committer (nil if none)
func (gc *GitConfig) GetCommitter() (pair *Pair, err error) {
	name, err := gc.getKey("git-committer-name")
	if err != nil {
		return nil, err
	}

	email, err := gc.getKey("git-committer-email")
	if err != nil {
		return nil, err
	}

	if name == "" || email == "" {
		return nil, nil
	}

	return &Pair{
		Name:  name,
		Email: email,
	}, nil
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

func (gc *GitConfig) unsetKey(key string) (err error) {
	if err = newIgnorableCommand(
		gc.configCommand("--unset-all", fmt.Sprintf("%s.%s", gc.Namespace, key)),
		5).Run(); err != nil {
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
