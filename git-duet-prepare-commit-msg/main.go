package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"regexp"

	"github.com/git-duet/git-duet"
	"github.com/pborman/getopt"
)

func main() {

	getopt.Parse()
	commitMsgFile := getopt.Args()[0]
	var commitMsgSource string
	if len(getopt.Args()) > 1 {
		commitMsgSource = getopt.Args()[1]
	}

	configuration, err := duet.NewConfiguration()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	var gitConfig *duet.GitConfig
	if configuration.Global {
		gitConfig = &duet.GitConfig{
			Namespace:     configuration.Namespace,
			Scope:         duet.Global,
			SetUserConfig: configuration.SetGitUserConfig,
		}
	} else {
		gitConfig, err = duet.GetAuthorConfig(configuration.Namespace, configuration.SetGitUserConfig)
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}
	}

	committers, err := gitConfig.GetCommitters()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	if committers == nil || len(committers) == 0 {
		os.Exit(0)
	}

	commitMsg, err := ioutil.ReadFile(commitMsgFile)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	coAuthorTrailerRegexp := regexp.MustCompile(`Co-authored-by:\s.+\s<.+>`)
	trailerExists := coAuthorTrailerRegexp.Match(commitMsg)
	if trailerExists && commitMsgSource != "commit" {
		/* The goal here is to not add trailers in interactive rebasing or cherry-picking
		   since authorship doesn't get changed. Since this hook doesn't know whether it is invoked
		   as part of rebasing or cherry-picking, at the very least, it checks for existing trailers,
		   and if there is one, no new trailers will be appended.
		   Trailers will still be appended for "git commit --amend" in which case the
		   commitMsgSource's value is "commit". */
		os.Exit(0)
	}

	// override the default "addIfDifferentNeighbor" so that no duplicate trailers will get appended
	err = gitConfig.SetUnnamespacedKey("trailer.ifexists", "addIfDifferent")
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	for _, c := range committers {
		trailer := "Co-authored-by: " + c.Name + " <" + c.Email + ">"
		cmd := exec.Command("git", "interpret-trailers", "--in-place", "--trailer", trailer, commitMsgFile)
		err := cmd.Run()
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}
	}

	// prepend an empty line to the trailers block if there aren't trailers yet
	if trailerExists || commitMsgSource == "commit" {
		os.Exit(0)
	}
	commitMsg, err = ioutil.ReadFile(commitMsgFile)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	err = ioutil.WriteFile(commitMsgFile, []byte(fmt.Sprintf("\n%s", string(commitMsg))), 0644)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
