package cmdrunner

import (
	"git-duet"
	"git-duet/internal/cmd"
)

func Execute(commands ...cmd.Command) error {
	configuration, err := duet.NewConfiguration()
	if err != nil {
		return err
	}

	gitConfig, err := duet.GetAuthorConfig(configuration.Namespace)
	if err != nil {
		return err
	}

	for _, command := range commands {
		if err := command.Execute(); err != nil {
			return err
		}
	}

	if configuration.RotateAuthor {
		if err = gitConfig.RotateAuthor(); err != nil {
			return err
		}
	}

	return nil
}