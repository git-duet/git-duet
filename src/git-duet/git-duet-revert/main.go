package main

import (
	"fmt"
	"os"

	"git-duet/internal/cmd"
)

func main() {
	err := cmd.ExecuteWithSignoff("revert")
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
