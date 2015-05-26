package main

import (
	"fmt"
	"os"

	"code.google.com/p/getopt"

	duet "github.com/jszwedko/go-git-duet"
)

func main() {
	var (
		quiet  = getopt.BoolLong("quiet", 'q', "Silence output")
		global = getopt.BoolLong("global", 'g', "Change global config")
		help   = getopt.BoolLong("help", 'h', "Help")
	)

	getopt.Parse()

	if *help {
		getopt.Usage()
		os.Exit(0)
	}

	configuration, err := duet.NewConfiguration()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	gitConfig := &duet.GitConfig{
		Namespace: configuration.Namespace,
		Global:    *global,
	}

	if getopt.NArgs() == 0 {
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

		printAuthor(author)
		printCommitter(committer)
		os.Exit(0)
	}

	if getopt.NArgs() != 2 {
		fmt.Println("must specify two sets of initials")
		os.Exit(1)
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

	committer, err := pairs.ByInitials(getopt.Arg(1))
	if err != nil {
		fmt.Println(err)
		os.Exit(86)
	}
	if err = gitConfig.SetCommitter(committer); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	if !*quiet {
		printAuthor(author)
		printCommitter(committer)
	}
}

func printAuthor(author *duet.Pair) {
	if author == nil {
		return
	}

	fmt.Printf("GIT_AUTHOR_NAME='%s'\n", author.Name)
	fmt.Printf("GIT_AUTHOR_EMAIL='%s'\n", author.Email)
}

func printCommitter(committer *duet.Pair) {
	if committer == nil {
		return
	}

	fmt.Printf("GIT_COMMITTER_NAME='%s'\n", committer.Name)
	fmt.Printf("GIT_COMMITTER_EMAIL='%s'\n", committer.Email)
}
