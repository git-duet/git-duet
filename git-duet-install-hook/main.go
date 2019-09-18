package main

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"os/user"
	"path"
	"strings"

	duet "github.com/git-duet/git-duet"
	"github.com/pborman/getopt"
)

const preCommit = "pre-commit"
const prepareCommitMsg = "prepare-commit-msg"
const postCommit = "post-commit"
const sheBangBash = "#!/usr/bin/env bash\n"
const preCommitHook = `exec git duet-pre-commit "$@"`
const prepareCommitMsgHook = `exec git duet-prepare-commit-msg "$@"`
const postCommitHook = `exec git duet-post-commit "$@"`

func main() {
	var (
		quiet = getopt.BoolLong("quiet", 'q', "Silence output")
		help  = getopt.BoolLong("help", 'h', "Help")
	)

	getopt.Parse()
	getopt.SetParameters(fmt.Sprintf("{ %s | %s | %s }", preCommit, prepareCommitMsg, postCommit))

	if *help {
		getopt.Usage()
		os.Exit(0)
	}

	args := getopt.Args()
	if len(args) != 1 {
		getopt.Usage()
		os.Exit(1)
	}
	hookFileName := args[0]

	var hook string
	if hookFileName == preCommit {
		hook = preCommitHook
	} else if hookFileName == prepareCommitMsg {
		hook = prepareCommitMsgHook
	} else if hookFileName == postCommit {
		hook = postCommitHook
	} else {
		getopt.Usage()
		os.Exit(1)
	}

	config, err := duet.NewConfiguration()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	var hooksDir string
	if config.Global {
		gitConfig := &duet.GitConfig{Namespace: config.Namespace, SetUserConfig: config.SetGitUserConfig}
		gitConfig.Scope = duet.Global
		templateDir, err := gitConfig.GetInitTemplateDir()
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}
		if templateDir == "" {
			usr, err := user.Current()
			if err != nil {
				fmt.Println(err)
				os.Exit(1)
			}
			templateDir = path.Join(usr.HomeDir, ".git-template")
			if err := gitConfig.SetInitTemplateDir(templateDir); err != nil {
				fmt.Println(err)
				os.Exit(1)
			}
		}
		if err := os.MkdirAll(path.Join(templateDir, "hooks"), os.ModePerm); err != nil {
			fmt.Println(err)
			os.Exit(1)
		}
		hooksDir = path.Join(templateDir, "hooks")
	} else {
		hooksDir = getLocalHooksDir()
	}

	hookPath := path.Join(hooksDir, hookFileName)

	hookFile, err := os.OpenFile(hookPath, os.O_CREATE|os.O_RDWR, os.ModePerm)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	defer hookFile.Close()

	b, err := ioutil.ReadAll(hookFile)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	contents := strings.TrimSpace(string(b))
	if contents != "" {
		if hook == preCommitHook && !strings.Contains(contents, preCommitHook) ||
			hook == prepareCommitMsgHook && !strings.Contains(contents, prepareCommitMsgHook) ||
			hook == postCommitHook && !strings.Contains(contents, postCommitHook) {
			fmt.Printf("can't install hook: file %s already exists\n", hookPath)
			os.Exit(1)
		}
		os.Exit(0) // hook file with the desired content already exists
	}

	if _, err = hookFile.WriteString(sheBangBash + hook); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	if !*quiet {
		fmt.Printf("git-duet-install-hook: Installed hook to %s\n", hookPath)
	}

}

func getLocalHooksDir() string {
	output := new(bytes.Buffer)
	cmd := exec.Command("git", "rev-parse", "--show-toplevel")
	cmd.Stdout = output
	if err := cmd.Run(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	return path.Join(strings.TrimSpace(output.String()), ".git", "hooks")
}
