package main

import (
	"errors"
	"fmt"
	"os"
	"os/exec"

	"go-git-duet"
)

func main() {
	configuration, err := duet.NewConfiguration()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	gitConfig, err := getGitConfig(configuration.Namespace)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	author, err := gitConfig.GetAuthor()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	committer, err := gitConfig.GetCommitter()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	args := os.Args[1:]
	if committer != nil {
		args = append([]string{"--signoff"}, args...)
	} else {
		committer = author
	}

	cmd := exec.Command("git", append([]string{"commit"}, args...)...)
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
		fmt.Println(err)
		os.Exit(1)
	}

	if configuration.RotateAuthor {
		if err = gitConfig.RotateAuthor(); err != nil {
			fmt.Println(err)
			os.Exit(1)
		}
	}
}

func getGitConfig(namespace string) (config *duet.GitConfig, err error) {
	configs := []*duet.GitConfig{
		&duet.GitConfig{Namespace: namespace, Local: true},
		&duet.GitConfig{Namespace: namespace, Global: true},
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
