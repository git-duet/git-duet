package main

import (
	"fmt"
	"os"
	"os/exec"

	duet "github.com/git-duet/git-duet"
	"github.com/pborman/getopt"
)

var (
	// VersionString is the git tag this binary is associated with
	VersionString string
	// RevisionString is the git rev this binary is associated with
	RevisionString string
)

func main() {
	var (
		quiet   = getopt.BoolLong("quiet", 'q', "Silence output")
		global  = getopt.BoolLong("global", 'g', "Change global config")
		help    = getopt.BoolLong("help", 'h', "Help")
		version = getopt.BoolLong("version", 'v', "Version")
		show    = getopt.BoolLong("show", 's', "Show")
	)

	getopt.Parse()

	if *help {
		getopt.Usage()
		os.Exit(0)
	}

	if *version {
		fmt.Printf("%s (%s)\n", VersionString, RevisionString)
		os.Exit(0)
	}

	configuration, err := duet.NewConfiguration()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	gitConfig := &duet.GitConfig{Namespace: configuration.Namespace, SetUserConfig: configuration.SetGitUserConfig}
	if *global || configuration.Global {
		gitConfig.Scope = duet.Global
	}

	if (configuration.DefaultUpdate && getopt.NArgs() == 0) || (getopt.NArgs() != 0 && getopt.NArgs() < 2) {
		fmt.Println("must specify at least two sets of initials")
		os.Exit(1)
	}

	if getopt.NArgs() == 0 || *show {
		author, err := gitConfig.GetAuthor()
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}
		committers, err := gitConfig.GetCommitters()
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}

		if committers == nil && author != nil {
			committers = []*duet.Pair{author}
		}

		printAuthor(author)
		printNextComitter(committers)
		if configuration.CoAuthoredBy {
			installHook("prepare-commit-msg")
			// SetAuthor is needed in case neither GIT_DUET_CO_AUTHORED_BY nor GIT_DUET_SET_GIT_USER_CONFIG was set previously
			if author != nil {
				if err = gitConfig.SetAuthor(author); err != nil {
					fmt.Println(err)
					os.Exit(1)
				}
			}
			if configuration.RotateAuthor {
				installHook("post-commit")
			}
		}
		os.Exit(0)
	}

	pairs, err := duet.NewPairsFromFile(configuration.PairsFile, configuration.EmailLookup)
	if err != nil {
		fmt.Println(err)
		os.Exit(0)
	}

	author, err := pairs.ByInitials(getopt.Arg(0))
	if err != nil {
		fmt.Println(err)
		os.Exit(86)
	}
	if err = gitConfig.SetAuthor(author); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	var committers []*duet.Pair

	for _, initials := range getopt.Args()[1:] {
		committer, err := pairs.ByInitials(initials)
		if err != nil {
			fmt.Println(err)
			os.Exit(86)
		}

		committers = append(committers, committer)
	}

	if err = gitConfig.SetCommitters(committers...); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	if !*quiet {
		printAuthor(author)
		printNextComitter(committers)
	}

	if configuration.CoAuthoredBy {
		installHook("prepare-commit-msg")
		if configuration.RotateAuthor {
			installHook("post-commit")
		}
	}
}

func printAuthor(author *duet.Pair) {
	if author == nil {
		return
	}

	fmt.Printf("GIT_AUTHOR_NAME='%s'\n", author.Name)
	fmt.Printf("GIT_AUTHOR_EMAIL='%s'\n", author.Email)
}

func printNextComitter(committers []*duet.Pair) {
	if committers == nil || len(committers) == 0 {
		return
	}

	fmt.Printf("GIT_COMMITTER_NAME='%s'\n", committers[0].Name)
	fmt.Printf("GIT_COMMITTER_EMAIL='%s'\n", committers[0].Email)
}

func installHook(hookType string) {
	cmd := exec.Command("git-duet-install-hook", hookType)
	cmd.Stderr = os.Stderr
	cmd.Stdout = os.Stdout

	err := cmd.Run()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
