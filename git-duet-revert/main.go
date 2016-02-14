package main

import (
	"fmt"
	"os"

	"github.com/git-duet/git-duet/internal/cmd"
	"github.com/git-duet/git-duet/internal/cmdrunner"
)

func main() {
	err := cmdrunner.Execute(cmd.NewWithSignoff("revert"))
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
