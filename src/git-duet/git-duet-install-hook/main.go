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

type Hook struct {
	Name string
}

func (h *Hook) Install(dest string) error {
	hookPath := path.Join(dest, ".git", "hooks", h.Name)
	hookFile, err := os.OpenFile(hookPath, os.O_CREATE|os.O_EXCL|os.O_WRONLY, os.ModePerm)
	if err != nil {
		return err
	}
	defer hookFile.Close()

	if _, err = fmt.Fprintln(hookFile, "#!/usr/bin/env bash"); err != nil {
		return err
	}

	if _, err = fmt.Fprintf(hookFile, `exec git duet-%s "$@"`, h.Name); err != nil {
		return err
	}

	return nil
}

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

	hookPath := strings.TrimSpace(output.String())

	hooks := []*Hook{
		&Hook{Name: "pre-commit"},
		&Hook{Name: "prepare-commit-msg"},
	}

	for _, hook := range hooks {
		if err := hook.Install(hookPath); err != nil {
			fmt.Println(err)
			os.Exit(1)
		}

		if !*quiet {
			fmt.Printf("git-duet-install-hook: Installed %s hook to %s\n", hook.Name, hookPath)
		}
	}
}
