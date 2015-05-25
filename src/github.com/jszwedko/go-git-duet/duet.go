package duet

import "os/exec"

type Runner interface {
	Run() error
}

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

func runMultiple(cmds ...Runner) (err error) {
	for _, cmd := range cmds {
		err = cmd.Run()
		if err != nil {
			return err
		}
	}

	return nil
}
