package main

import (
	"fmt"
	"os"
	"os/exec"
	"path"

	"code.google.com/p/getopt"

	duet "github.com/jszwedko/go-git-duet"
)

type Configuration struct {
	Namespace   string
	AuthorsFile string
	EmailLookup string
}

func NewConfiguration() *Configuration {
	return &Configuration{
		Namespace:   getenvDefault("GIT_DUET_CONFIG_NAMESPACE", "duet.env"),
		AuthorsFile: getenvDefault("GIT_DUET_AUTHORS_FILE", path.Join(os.Getenv("HOME"), ".git-authors")),
		EmailLookup: os.Getenv("GIT_DUET_EMAIL_LOOKUP_COMMAND"),
	}
}

func getenvDefault(key, defaultValue string) (value string) {
	value = os.Getenv(key)
	if value == "" {
		value = defaultValue
	}

	return value
}

func main() {
	quiet := getopt.BoolLong("quiet", 'q', "Silence output")
	global := getopt.BoolLong("global", 'g', "Change global config")
	help := getopt.BoolLong("help", 'h', "Help")
	configuration := NewConfiguration()

	getopt.Parse()

	if *help {
		getopt.Usage()
		os.Exit(0)
	}

	if getopt.NArgs() == 0 {
		cmd := exec.Command("git", "config", "--get-regexp", configuration.Namespace)
		cmd.Stdout = os.Stdout
		if err := cmd.Run(); err != nil {
			fmt.Println(err)
			os.Exit(1)
		}
		os.Exit(0)
	}

	initials := getopt.Arg(0)

	authors, err := duet.NewAuthorsFromFile(configuration.AuthorsFile, configuration.EmailLookup)
	if err != nil {
		fmt.Println(err)
		os.Exit(0)
	}

	author, err := authors.ByInitials(initials)
	if err != nil {
		fmt.Println(err)
		os.Exit(86)
	}

	gitConfig := &duet.GitConfig{
		Namespace: configuration.Namespace,
		Global:    *global,
	}

	if err = gitConfig.SetAuthor(author); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	if !*quiet {
		printAuthor(author)
	}
}

func printAuthor(author *duet.Author) {
	fmt.Printf("GIT_AUTHOR_NAME='%s'\n", author.Name)
	fmt.Printf("GIT_AUTHOR_EMAIL='%s'\n", author.Email)
}
