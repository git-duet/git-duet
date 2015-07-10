package main

import (
	"fmt"
	"os"
	"time"

	"git-duet"
)

func main() {
	configuration, err := duet.NewConfiguration()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	gitConfig := &duet.GitConfig{
		Namespace: configuration.Namespace,
	}

	mtime, err := gitConfig.GetMtime()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	if mtime.Add(configuration.StaleCutoff).Before(time.Now()) {
		fmt.Println("your git duet settings are stale")
		fmt.Println("update them with `git duet` or `git solo`.")
		os.Exit(1)
	}
}
