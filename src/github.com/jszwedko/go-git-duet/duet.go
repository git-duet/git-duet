package duet

import (
	"fmt"
	"os/exec"
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

func (gc *GitConfig) SetAuthor(author *Author) (err error) {
	return runCommands(
		gc.configCommand("user.name", author.Name),
		gc.configCommand("user.email", author.Email),
		gc.configCommand(fmt.Sprintf("%s.git-author-name", gc.Namespace), author.Name),
		gc.configCommand(fmt.Sprintf("%s.git-author-email", gc.Namespace), author.Email),
	)
}
