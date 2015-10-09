package main

import (
	"fmt"
	"os"

	"git-duet/internal/cmd"
	"git-duet/internal/cmdrunner"
)

func main() {
	err := cmdrunner.Execute(cmd.NewWithSignoff("commit"))
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
