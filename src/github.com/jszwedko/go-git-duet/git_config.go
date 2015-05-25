package duet

import (
	"bytes"
	"fmt"
	"os/exec"
	"strings"
)

type GitConfig struct {
	Namespace string
	Global    bool
}

func (gc *GitConfig) ClearCommitter() (err error) {
	if err = gc.unsetKey("git-committer-name"); err != nil {
		return err
	}
	if err = gc.unsetKey("git-committer-name"); err != nil {
		return err
	}
	return nil
}

func (gc *GitConfig) SetAuthor(pair *Pair) (err error) {
	if err = gc.setKey("git-author-name", pair.Name); err != nil {
		return err
	}
	if err = gc.setKey("git-author-email", pair.Email); err != nil {
		return err
	}
	return nil
}

func (gc *GitConfig) SetCommitter(committer *Pair) (err error) {
	if err = gc.setKey("git-committer-name", committer.Name); err != nil {
		return err
	}
	if err = gc.setKey("git-committer-email", committer.Email); err != nil {
		return err
	}
	return nil
}

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
	return newIgnorableCommand(
		gc.configCommand("--unset-all", fmt.Sprintf("%s.%s", gc.Namespace, key)),
		5).Run()
}

func (gc *GitConfig) setKey(key, value string) (err error) {
	return gc.configCommand(fmt.Sprintf("%s.%s", gc.Namespace, key), value).Run()
}

func (gc *GitConfig) configCommand(args ...string) *exec.Cmd {
	config := []string{"config"}
	if gc.Global {
		config = append(config, "--global")
	}
	config = append(config, args...)
	return exec.Command("git", config...)
}
