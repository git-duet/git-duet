package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"regexp"
	"strings"

	"github.com/git-duet/git-duet"
	"github.com/pborman/getopt"
)

func main() {

	getopt.Parse()
	commitMsgFile := getopt.Args()[0]

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
		fmt.Print(err)
		os.Exit(1)
	}

	coAuthorTrailerRegexp := regexp.MustCompile(`Co-authored-by:\s.+\s<.+>`)
	if coAuthorTrailerRegexp.Match(commitMsg) {
		// don't append further trailers if there are already trailers
		// this avoids duplicate trailers when interactively rebasing or cherry-picking
		os.Exit(0)
	}

	var coAuthorsTrailer string
	for _, c := range committers {
		coAuthorsTrailer += "Co-authored-by: " + c.Name + " <" + c.Email + ">\n"
	}
	coAuthorsTrailer = strings.TrimSuffix(coAuthorsTrailer, "\n")

	err = ioutil.WriteFile(commitMsgFile, []byte(fmt.Sprintf("%s\n%s", string(commitMsg), coAuthorsTrailer)), 0644)
	if err != nil {
		fmt.Print(err)
		os.Exit(1)
	}
}
