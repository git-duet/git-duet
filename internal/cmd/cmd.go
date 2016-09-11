// cmd houses shared command logic between git-duet commands

package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/git-duet/git-duet"
)

type Command struct {
	Signoff    bool
	Subcommand string
	Args       []string
}

func New(subcommand string, args ...string) Command {
	cmd := Command{}
	cmd.Subcommand = subcommand

	// If we're explicitly providing args, use them.
	// Otherwise, we're forwarding from user input.
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

	var gitConfig *duet.GitConfig
	if configuration.Global {
		gitConfig = &duet.GitConfig{Namespace: configuration.Namespace, Scope: duet.Global}
	} else {
		gitConfig, err = duet.GetAuthorConfig(configuration.Namespace)
		if err != nil {
			return err
		}
	}

	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	author, err := gitConfig.GetAuthor()
	if err != nil {
		return err
	}

	if author == nil {
		return err
	}

	committers, err := gitConfig.GetCommitters()
	if err != nil {
		return err
	}

	var committer *duet.Pair
	if committers != nil && len(committers) > 0 && duetcmd.Signoff {
		duetcmd.Args = append([]string{"--signoff"}, duetcmd.Args...)
		committer = committers[0]
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
