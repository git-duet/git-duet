package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path"
	"strings"

	"code.google.com/p/getopt"
)

const hook = `
#!/usr/bin/env bash
exec git duet-pre-commit "$@"
`

func main() {
	var (
		quiet = getopt.BoolLong("quiet", 'q', "Silence output")
		help  = getopt.BoolLong("help", 'h', "Help")
	)

	getopt.Parse()

	if *help {
		getopt.Usage()
		os.Exit(0)
	}

	output := new(bytes.Buffer)
	cmd := exec.Command("git", "rev-parse", "--show-toplevel")
	cmd.Stdout = output
	if err := cmd.Run(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	hookPath := path.Join(strings.TrimSpace(output.String()), ".git", "hooks", "pre-commit")

	hookFile, err := os.OpenFile(hookPath, os.O_CREATE|os.O_EXCL|os.O_WRONLY, os.ModePerm)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	defer hookFile.Close()

	if _, err = hookFile.WriteString(hook); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	if !*quiet {
		fmt.Printf("git-duet-install-hook: Installed hook to %s\n", hookPath)
	}
}
