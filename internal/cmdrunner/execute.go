package cmdrunner

import (
	"github.com/git-duet/git-duet/internal/cmd"

	"github.com/git-duet/git-duet"
)

func Execute(commands ...cmd.Command) error {
	configuration, err := duet.NewConfiguration()
	if err != nil {
		return err
	}

	var gitConfig *duet.GitConfig
	if configuration.Global {
		gitConfig = &duet.GitConfig{
			Namespace:     configuration.Namespace,
			Scope:         duet.Global,
			SetUserConfig: configuration.SetGitUserConfig,
		}
	} else {
		gitConfig, err = duet.GetAuthorConfig(configuration.Namespace, configuration.SetGitUserConfig)
		if err != nil {
			return err
		}
	}

	for _, command := range commands {
		if err := command.Execute(); err != nil {
			return err
		}
	}

	if configuration.RotateAuthor {
		if err := gitConfig.RotateAuthor(); err != nil {
			return err
		}
	}

	return nil
}
