package main

import (
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"

	"github.com/git-duet/git-duet/internal/cmd"
	"github.com/git-duet/git-duet/internal/cmdrunner"
)

func main() {
	err := cmd.New("merge").Execute()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	output, err := exec.Command("git", "rev-list", "--merges", "HEAD~1..HEAD").Output()
	if err != nil { // if error, check if it was because there was only one or zero commits in the repo
		output, err = exec.Command("git", "rev-list", "--count", "HEAD").Output()
		if err != nil {
			fmt.Printf("error checking if HEAD has more than 1 commit: %s\n", err)
			os.Exit(1)
		}
		numCommits, err := strconv.Atoi(strings.TrimSpace(string(output)))
		if err != nil {
			fmt.Printf("error checking if HEAD has more than 1 commit: %s\n", err)
			os.Exit(1)
		}
		if numCommits <= 1 { // couldn't have any merges yet
			return
		}

		fmt.Printf("error checking if HEAD was a merge: %s\n", err)
		os.Exit(1)
	}

	if len(output) == 0 { // merge was fast-forward
		return
	}

	// we want to rotate the author, so use cmdrunner
	err = cmdrunner.Execute(
		cmd.NewWithSignoff("commit", "--amend", "--no-edit"),
	)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
