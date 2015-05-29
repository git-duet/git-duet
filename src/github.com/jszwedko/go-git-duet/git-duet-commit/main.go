package main

import (
	"fmt"
	"os"
	"os/exec"

	duet "github.com/jszwedko/go-git-duet"
)

func main() {
	configuration, err := duet.NewConfiguration()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	gitConfig := &duet.GitConfig{
		Namespace: configuration.Namespace,
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
}
