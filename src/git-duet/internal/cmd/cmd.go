// cmd houses shared command logic between git-duet commands
//
// This package should not be depended on and will be not be able to be
// referenced when Go 1.5 rolls out support for internal packages to all
// repositories

package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"git-duet"
)

// ExecuteWithSignoff executes a signoff-able git command
func ExecuteWithSignoff(subcommand string) error {
	configuration, err := duet.NewConfiguration()
	if err != nil {
		return err
	}

	gitConfig, err := duet.GetAuthorConfig(configuration.Namespace)
	if err != nil {
		return err
	}

	author, err := gitConfig.GetAuthor()
	if err != nil {
		return err
	}

	if author == nil {
		return err
	}

	committer, err := gitConfig.GetCommitter()
	if err != nil {
		return err
	}

	args := os.Args[1:]
	if committer != nil {
		args = append([]string{"--signoff"}, args...)
	} else {
		committer = author
	}

	cmd := exec.Command("git", append([]string{subcommand}, args...)...)
	cmd.Stdin = os.Stdin
	cmd.Stderr = os.Stderr
	cmd.Stdout = os.Stdout
	cmd.Env = append(os.Environ(),
		fmt.Sprintf("GIT_AUTHOR_NAME=%s", author.Name),
		fmt.Sprintf("GIT_AUTHOR_EMAIL=%s", author.Email),
		fmt.Sprintf("GIT_COMMITTER_NAME=%s", committer.Name),
		fmt.Sprintf("GIT_COMMITTER_EMAIL=%s", committer.Email),
	)
	err = cmd.Run()
	if err != nil {
		return err
	}

	if configuration.RotateAuthor {
		if err = gitConfig.RotateAuthor(); err != nil {
			return err
		}
	}
	return nil
}
