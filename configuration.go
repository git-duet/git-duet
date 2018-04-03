package duet

import (
	"os"
	"os/exec"
	"path"
	"strconv"
	"strings"
	"time"
)

// Configuration represents package configuration (shared by commands)
type Configuration struct {
	Namespace        string
	PairsFile        string
	EmailLookup      string
	CoAuthoredBy     bool
	Global           bool
	RotateAuthor     bool
	SetGitUserConfig bool
	StaleCutoff      time.Duration
}

// NewConfiguration initializes Configuration from the environment
// Returns an error if it cannot parse the staleness timeout as an integer or
// the global var as a bool
func NewConfiguration() (config *Configuration, err error) {
	config = &Configuration{
		Namespace:   getenvDefault("GIT_DUET_CONFIG_NAMESPACE", "duet.env"),
		EmailLookup: os.Getenv("GIT_DUET_EMAIL_LOOKUP_COMMAND"),
	}

	if config.PairsFile, err = getPairsFile(); err != nil {
		return nil, err
	}

	cutoff, err := strconv.Atoi(getenvDefault("GIT_DUET_SECONDS_AGO_STALE", "1200"))
	if err != nil {
		return nil, err
	}

	if config.Global, err = strconv.ParseBool(getenvDefault("GIT_DUET_GLOBAL", "0")); err != nil {
		return nil, err
	}

	if config.RotateAuthor, err = strconv.ParseBool(getenvDefault("GIT_DUET_ROTATE_AUTHOR", "0")); err != nil {
		return nil, err
	}

	if config.CoAuthoredBy, err = strconv.ParseBool(getenvDefault("GIT_DUET_CO_AUTHORED_BY", "0")); err != nil {
		return nil, err
	}

	defaultSetGitUserConfig := "0"
	if config.CoAuthoredBy {
		defaultSetGitUserConfig = "1"
	}
	if config.SetGitUserConfig, err = strconv.ParseBool(getenvDefault("GIT_DUET_SET_GIT_USER_CONFIG", defaultSetGitUserConfig)); err != nil {
		return nil, err
	}

	config.StaleCutoff = time.Duration(cutoff) * time.Second

	return config, nil
}

func getPairsFile() (value string, err error) {

	authorsFile := ".git-authors"

	if os.Getenv("GIT_DUET_AUTHORS_FILE") != "" {
		return os.Getenv("GIT_DUET_AUTHORS_FILE"), nil
	}

	gitDirectory, err := exec.Command("git", "rev-parse", "--show-toplevel").Output()
	if err != nil {
		return "", err
	}

	gitDirectoryAuthors := path.Join(strings.TrimSpace(string(gitDirectory)), authorsFile)
	if _, err := os.Stat(gitDirectoryAuthors); err == nil {
		return gitDirectoryAuthors, nil
	}

	return path.Join(os.Getenv("HOME"), authorsFile), nil
}

func getenvDefault(key, defaultValue string) (value string) {
	value = os.Getenv(key)
	if value == "" {
		value = defaultValue
	}

	return value
}
