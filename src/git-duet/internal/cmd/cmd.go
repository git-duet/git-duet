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

type Command struct {
	Signoff bool
	Subcommand string
	Args []string
}

func New(subcommand string, args ...string) Command {
	cmd := Command{}
	cmd.Subcommand = subcommand

	if len(args) == 0 {
		cmd.Args = os.Args[1:]
	} else {
		cmd.Args = args
	}

	return cmd
}

func NewWithSignoff(subcommand string, args ...string) Command {
	cmd := New(subcommand, args...)
	cmd.Signoff = true

	return cmd
}

func (duetcmd Command) Execute() error {
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

	if committer != nil && duetcmd.Signoff {
		duetcmd.Args = append([]string{"--signoff"}, duetcmd.Args...)
	} else {
		committer = author
	}

	cmd := exec.Command("git", append([]string{duetcmd.Subcommand}, duetcmd.Args...)...)
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

	return nil
}
