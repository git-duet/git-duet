package main

import (
	"fmt"
	"os"

	"git-duet/internal/cmd"
	"git-duet/internal/cmdrunner"
)

func main() {
	err := cmdrunner.Execute(
		cmd.New("merge"),
		cmd.NewWithSignoff("commit", "--amend", "--no-edit"))

	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
