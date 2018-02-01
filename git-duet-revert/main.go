package main

import (
	"fmt"
	"os"

	"github.com/git-duet/git-duet"
	"github.com/git-duet/git-duet/internal/cmd"
	"github.com/git-duet/git-duet/internal/cmdrunner"
)

func main() {
	configuration, err := duet.NewConfiguration()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	var command cmd.Command
	if configuration.CoAuthoredBy {
		command = cmd.NewWithCoAuthoredBy("revert")
	} else {
		command = cmd.NewWithSignoff("revert")
	}

	err = cmdrunner.Execute(command)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
