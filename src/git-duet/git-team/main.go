package main

import (
	"fmt"
	"os"

	"code.google.com/p/getopt"

	duet "git-duet"
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

	if getopt.NArgs() == 0 {
		gitConfig, err := duet.GetAuthorConfig(configuration.Namespace)
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

		if committer == nil {
			committer = author
		}

		printAuthor(author)
		printCommitter(committer)
		os.Exit(0)
	}

	gitConfig := &duet.GitConfig{
		Namespace: configuration.Namespace,
	}
	if configuration.Global || *global {
		gitConfig.Scope = duet.Global
	}

	if getopt.NArgs() <= 2 {
		fmt.Println("must specify more than two sets of initials")
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

	number_of_committers := getopt.NArgs() - 1
	committers := make([]*duet.Pair, number_of_committers)

	for i := 1; i < getopt.NArgs(); i++ {
		committer, err := pairs.ByInitials(getopt.Arg(i))
		if err == nil {
			committers[i-1] = committer
		} else {
			fmt.Println(err)
			os.Exit(1)
		}
	}

	committer := makeTeamCommitter(committers)

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

func makeTeamCommitter(arrayOfCommitters []*duet.Pair) (committer *duet.Pair) {
	var returnCommitter duet.Pair
	for index, pointerToPair := range arrayOfCommitters {
		tempCommitter := *pointerToPair
		if index > 0 {
			returnCommitter.Initials += ", "
			returnCommitter.Name += ", "
			returnCommitter.Email += ", "
		}
		returnCommitter.Initials += tempCommitter.Initials
		returnCommitter.Name += tempCommitter.Name
		returnCommitter.Email += tempCommitter.Email
	}
	return &returnCommitter
}
