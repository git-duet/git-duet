package duet

import (
	"os"
	"path"
	"strconv"
	"time"
)

// Configuration represents package configuration (shared by commands)
type Configuration struct {
	Namespace   string
	PairsFile   string
	EmailLookup string
	Global      bool
	StaleCutoff time.Duration
}

// NewConfiguration initializes Configuration from the environment
// Returns an error if it cannot parse the staleness timeout as an integer
func NewConfiguration() (config *Configuration, err error) {
	config = &Configuration{
		Namespace:   getenvDefault("GIT_DUET_CONFIG_NAMESPACE", "duet.env"),
		PairsFile:   getenvDefault("GIT_DUET_AUTHORS_FILE", path.Join(os.Getenv("HOME"), ".git-authors")),
		EmailLookup: os.Getenv("GIT_DUET_EMAIL_LOOKUP_COMMAND"),
	}

	cutoff, err := strconv.Atoi(getenvDefault("'GIT_DUET_SECONDS_AGO_STALE'", "1200"))
	if err != nil {
		return nil, err
	}

	if config.Global, err = strconv.ParseBool(getenvDefault("GIT_DUET_GLOBAL", "0")); err != nil {
		return nil, err
	}

	config.StaleCutoff = time.Duration(cutoff) * time.Second

	return config, nil
}

func getenvDefault(key, defaultValue string) (value string) {
	value = os.Getenv(key)
	if value == "" {
		value = defaultValue
	}

	return value
}
