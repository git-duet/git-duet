package main

import (
	"fmt"
	"os"

	"code.google.com/p/getopt"

	"github.com/git-duet/git-duet"
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

	if getopt.NArgs() == 0 {
		author, err := gitConfig.GetAuthor()
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}

		printAuthor(author)
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

	if err = gitConfig.ClearCommitter(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	if !*quiet {
		printAuthor(author)
	}
}

func printAuthor(author *duet.Pair) {
	if author == nil {
		return
	}

	fmt.Printf("GIT_AUTHOR_NAME='%s'\n", author.Name)
	fmt.Printf("GIT_AUTHOR_EMAIL='%s'\n", author.Email)
}
