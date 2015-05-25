package duet

import (
	"os"
	"path"
)

type Configuration struct {
	Namespace   string
	PairsFile   string
	EmailLookup string
}

func NewConfiguration() *Configuration {
	return &Configuration{
		Namespace:   getenvDefault("GIT_DUET_CONFIG_NAMESPACE", "duet.env"),
		PairsFile:   getenvDefault("GIT_DUET_AUTHORS_FILE", path.Join(os.Getenv("HOME"), ".git-authors")),
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
