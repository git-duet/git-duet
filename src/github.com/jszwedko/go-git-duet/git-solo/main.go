package main

import (
	"fmt"
	"os"

	"code.google.com/p/getopt"

	duet "github.com/jszwedko/go-git-duet"
)

func main() {
	var (
		quiet         = getopt.BoolLong("quiet", 'q', "Silence output")
		global        = getopt.BoolLong("global", 'g', "Change global config")
		help          = getopt.BoolLong("help", 'h', "Help")
		configuration = duet.NewConfiguration()
	)

	getopt.Parse()

	if *help {
		getopt.Usage()
		os.Exit(0)
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

		printAuthor(author)
		os.Exit(0)
	}

	initials := getopt.Arg(0)

	pairs, err := duet.NewPairsFromFile(configuration.PairsFile, configuration.EmailLookup)
	if err != nil {
		fmt.Println(err)
		os.Exit(0)
	}

	author, err := pairs.ByInitials(initials)
	if err != nil {
		fmt.Println(err)
		os.Exit(86)
	}

	if err = gitConfig.SetAuthor(author); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	if !*quiet {
		printAuthor(author)
	}
}

func printAuthor(author *duet.Pair) {
	fmt.Printf("GIT_AUTHOR_NAME='%s'\n", author.Name)
	fmt.Printf("GIT_AUTHOR_EMAIL='%s'\n", author.Email)
}
