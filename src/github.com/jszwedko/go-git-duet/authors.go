package duet

import (
	"fmt"
	"io/ioutil"
	"os"
	"strings"

	"gopkg.in/yaml.v1"
)

type Authors struct {
	file *authorsFile
}

type Author struct {
	Name  string
	Email string
}

type authorsFile struct {
	Pairs          map[string]string `yaml:"pairs"`
	Email          emailConfig       `yaml:"email"`
	EmailAddresses map[string]string `yaml:"email_addresses"`
	EmailTemplate  string            `yaml:"email_template"`
}

type emailConfig struct {
	Prefix string
	Domain string
}

func NewAuthorsFromFile(filename string) (a *Authors, err error) {
	af := &authorsFile{}

	file, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	contents, err := ioutil.ReadAll(file)
	if err != nil {
		return nil, err
	}

	err = yaml.Unmarshal(contents, &af)
	if err != nil {
		return nil, err
	}

	return &Authors{
		file: af,
	}, nil
}

func (a *Authors) ByInitials(initials string) (author *Author, err error) {
	authorString, ok := a.file.Pairs[initials]
	if !ok {
		return nil, fmt.Errorf("unknown initials %s", initials)
	}

	authorParts := strings.SplitN(authorString, ";", 2)
	name := strings.TrimSpace(authorParts[0])

	email := ""
	if e, ok := a.file.EmailAddresses[initials]; ok {
		email = e
	} else if len(authorParts) == 2 {
		email = fmt.Sprintf("%s@%s", strings.TrimSpace(authorParts[1]), a.file.Email.Domain)
	}

	return &Author{
		Name:  name,
		Email: email,
	}, nil
}
