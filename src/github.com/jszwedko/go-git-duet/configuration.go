package duet

import (
	"os"
	"path"
	"strconv"
	"time"
)

type Configuration struct {
	Namespace   string
	PairsFile   string
	EmailLookup string
	StaleCutoff time.Duration
}

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
