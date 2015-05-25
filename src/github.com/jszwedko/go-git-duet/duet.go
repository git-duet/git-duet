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

func runCommands(cmds ...*exec.Cmd) (err error) {
	for _, cmd := range cmds {
		err = cmd.Run()
		if err != nil {
			return err
		}
	}

	return nil
}

func (gc *GitConfig) configCommand(args ...string) *exec.Cmd {
	config := []string{"config"}
	if gc.Global {
		config = append(config, "--global")
	}
	config = append(config, args...)
	return exec.Command("git", config...)
}

func (gc *GitConfig) ClearCommitter() (err error) {
	return runCommands(
		gc.configCommand("--unset-all", fmt.Sprintf("%s.git-committer-name", gc.Namespace)),
		gc.configCommand("--unset-all", fmt.Sprintf("%s.git-committer-email", gc.Namespace)),
	)
}

func (gc *GitConfig) SetAuthor(pair *Pair) (err error) {
	return runCommands(
		gc.configCommand("user.name", pair.Name),
		gc.configCommand("user.email", pair.Email),
		gc.configCommand(fmt.Sprintf("%s.git-author-name", gc.Namespace), pair.Name),
		gc.configCommand(fmt.Sprintf("%s.git-author-email", gc.Namespace), pair.Email),
	)
}

func runCommand(cmd *exec.Cmd) (out string, err error) {
	output := new(bytes.Buffer)
	cmd.Stdout = output
	if err = cmd.Run(); err != nil {
		return "", err
	}
	return strings.TrimSpace(output.String()), nil
}

func (gc *GitConfig) GetAuthor() (pair *Pair, err error) {
	name, err := runCommand(gc.configCommand(fmt.Sprintf("%s.git-author-name", gc.Namespace)))
	if err != nil {
		return nil, err
	}

	email, err := runCommand(gc.configCommand(fmt.Sprintf("%s.git-author-email", gc.Namespace)))
	if err != nil {
		return nil, err
	}

	return &Pair{
		Name:  name,
		Email: email,
	}, nil
}
