package duet

import (
	"fmt"
	"os/exec"
)

type GitConfig struct {
	Namespace string
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

func (gc *GitConfig) ClearCommitter() (err error) {
	return runCommands(
		exec.Command("git", "config", "--unset-all", fmt.Sprintf("%s.git-committer-name", gc.Namespace)),
		exec.Command("git", "config", "--unset-all", fmt.Sprintf("%s.git-committer-email", gc.Namespace)),
	)
}

func (gc *GitConfig) SetAuthor(author *Author) (err error) {
	return runCommands(
		exec.Command("git", "config", "user.name", author.Name),
		exec.Command("git", "config", "user.email", author.Email),
		exec.Command("git", "config", fmt.Sprintf("%s.git-author-name", gc.Namespace), author.Name),
		exec.Command("git", "config", fmt.Sprintf("%s.git-author-email", gc.Namespace), author.Email),
	)
}
