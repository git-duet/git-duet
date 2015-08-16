package main

import (
	"fmt"
	"os"

	"git-duet/internal/cmd"
)

func main() {
	err := cmd.ExecuteWithSignoff("commit")
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
