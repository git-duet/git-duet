package duet

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"strings"

	"gopkg.in/yaml.v1"
)

type Pairs struct {
	file        *pairsFile
	emailLookup string
}

type Pair struct {
	Name  string
	Email string
}

type pairsFile struct {
	Pairs          map[string]string `yaml:"pairs"`
	Email          emailConfig       `yaml:"email"`
	EmailAddresses map[string]string `yaml:"email_addresses"`
	EmailTemplate  string            `yaml:"email_template"`
}

type emailConfig struct {
	Prefix string
	Domain string
}

func NewPairsFromFile(filename string, emailLookup string) (a *Pairs, err error) {
	af := &pairsFile{}

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

	return &Pairs{
		file:        af,
		emailLookup: emailLookup,
	}, nil
}

// buildEmail returns the email address for the given pair
// It returns the first email it finds while doing the following:
// - Run external lookup if provided
// - Pull from `email_addresses` map in config
// - Build using username (if provided) and domain
func (a *Pairs) buildEmail(initials, name, username string) (email string, err error) {
	if a.emailLookup != "" {
		var out bytes.Buffer

		cmd := exec.Command(a.emailLookup, initials, name, username)
		cmd.Stdout = &out

		if err := cmd.Run(); err != nil {
			return "", err
		}

		email = strings.TrimSpace(out.String())
		if email != "" {
			return email, nil
		}
	}

	if e, ok := a.file.EmailAddresses[initials]; ok {
		email = e
	} else if username != "" {
		email = fmt.Sprintf("%s@%s", strings.TrimSpace(username), a.file.Email.Domain)
	}

	return email, nil
}

func (a *Pairs) ByInitials(initials string) (pair *Pair, err error) {
	pairString, ok := a.file.Pairs[initials]
	if !ok {
		return nil, fmt.Errorf("unknown initials %s", initials)
	}

	pairParts := strings.SplitN(pairString, ";", 2)
	name := strings.TrimSpace(pairParts[0])
	username := ""
	if len(pairParts) == 2 {
		username = strings.TrimSpace(pairParts[1])
	}

	email, err := a.buildEmail(initials, name, username)
	if err != nil {
		return nil, err
	}

	return &Pair{
		Name:  name,
		Email: email,
	}, nil
}
