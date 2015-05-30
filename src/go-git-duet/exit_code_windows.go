// +build windows

package duet

import (
	"os/exec"
	"syscall"
)

func exitCode(err *exec.ExitError) int {
	return int(err.Sys().(syscall.WaitStatus).ExitCode)
}
