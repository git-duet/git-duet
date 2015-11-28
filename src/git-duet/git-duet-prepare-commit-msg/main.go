package main

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"regexp"

	"git-duet"

	"code.google.com/p/getopt"
)

func main() {
	getopt.Parse()

	if getopt.NArgs() == 0 {
		exitOnErr(errors.New("The prepare-commit-msg hook has invalid arguments"))
	}

	configuration, err := duet.NewConfiguration()
	if err != nil {
		exitOnErr(err)
	}

	gitConfig := &duet.GitConfig{
		Namespace: configuration.Namespace,
	}

	storyID, err := gitConfig.GetStoryID()
	if err != nil {
		exitOnErr(err)
	}

	if storyID == nil {
		os.Exit(0)
	}

	msgPath := getopt.Arg(0)
	msgFile, err := os.OpenFile(msgPath, os.O_RDWR, os.ModePerm)
	if err != nil {
		exitOnErr(err)
	}
	defer msgFile.Close()

	matcher := regexp.MustCompile(fmt.Sprintf(`\[#%v\]`, storyID))
	if matcher.MatchReader(bufio.NewReader(msgFile)) {
		os.Exit(0)
	}

	if _, err := msgFile.Seek(0, os.SEEK_SET); err != nil {
		exitOnErr(err)
	}

	if err = format(msgFile, storyID); err != nil {
		exitOnErr(err)
	}
}

func format(original *os.File, storyID *duet.StoryID) error {
	temporary, err := ioutil.TempFile("", ".COMMIT_MSG")
	if err != nil {
		return err
	}
	defer temporary.Close()

	reader := bufio.NewReader(original)
	written := false

	for {
		line, err := reader.ReadString('\n')
		if err != nil {
			if err != io.EOF {
				return err
			}
			break
		}

		if line == "\n" && !written {
			line = fmt.Sprintf("\n[#%v]\n\n", storyID)
			written = true
		}

		if _, err := fmt.Fprint(temporary, line); err != nil {
			return err
		}
	}

	if written {
		return replace(original, temporary)
	}

	if _, err := fmt.Fprintf(original, "\n\n[#%v]", storyID); err != nil {
		return err
	}

	return nil
}

func replace(dst *os.File, src *os.File) error {
	if _, err := src.Seek(0, os.SEEK_SET); err != nil {
		return err
	}

	if _, err := dst.Seek(0, os.SEEK_SET); err != nil {
		return err
	}

	if err := dst.Truncate(0); err != nil {
		return err
	}

	if _, err := io.Copy(dst, src); err != nil {
		return err
	}

	return nil
}

func exitOnErr(err error) {
	fmt.Fprintln(os.Stderr, err)
	os.Exit(1)
}
