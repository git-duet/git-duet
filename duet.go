package duet

import "os/exec"

type ignorableCommand struct {
	*exec.Cmd
	validFailureCodes []int
}

func newIgnorableCommand(cmd *exec.Cmd, validFailureCodes ...int) *ignorableCommand {
	return &ignorableCommand{
		Cmd:               cmd,
		validFailureCodes: validFailureCodes,
	}
}

func (cmd *ignorableCommand) Run() error {
	switch err := cmd.Cmd.Run().(type) {
	case *exec.ExitError:
		code := exitCode(err)
		for _, validFailureCode := range cmd.validFailureCodes {
			if code == validFailureCode {
				return nil
			}
		}
		return err
	default:
		return err
	}
}
