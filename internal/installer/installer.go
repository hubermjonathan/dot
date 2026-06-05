package installer

import (
	"fmt"
	"io"
	"os"
	"os/exec"
)

func BuildBrewArgs(formulae []string) []string {
	args := []string{"install"}
	args = append(args, formulae...)
	return args
}

func BuildCaskArgs(casks []string) []string {
	args := []string{"install", "--cask"}
	args = append(args, casks...)
	return args
}

// CommandError reports a failed subprocess.
type CommandError struct {
	Label string
	Err   error
}

func (e *CommandError) Error() string { return fmt.Sprintf("%s failed: %v", e.Label, e.Err) }
func (e *CommandError) Unwrap() error { return e.Err }

// run executes cmd with stdout+stderr both routed to out and returns a
// CommandError on failure. Callers (e.g. ui.Step) own the buffer.
func run(cmd *exec.Cmd, label string, out io.Writer) error {
	cmd.Stdout = out
	cmd.Stderr = out
	if err := cmd.Run(); err != nil {
		return &CommandError{Label: label, Err: err}
	}
	return nil
}

func InstallBrew(formulae []string, out io.Writer) error {
	if len(formulae) == 0 {
		return nil
	}
	return run(exec.Command("brew", BuildBrewArgs(formulae)...), "brew install", out)
}

func InstallCask(casks []string, out io.Writer) error {
	if len(casks) == 0 {
		return nil
	}
	return run(exec.Command("brew", BuildCaskArgs(casks)...), "brew install --cask", out)
}

// RunScripts runs each command with `sh -c`. stdout+stderr are routed to out.
// When interactive is true, the child also inherits the controlling stdin so
// prompts work; the caller is responsible for passing os.Stdout/os.Stderr (or
// the equivalent) as out so prompts are visible.
func RunScripts(commands []string, label string, interactive bool, out io.Writer) []error {
	var errs []error
	for _, c := range commands {
		cmd := exec.Command("sh", "-c", c)
		if interactive {
			cmd.Stdin = os.Stdin
		}
		if err := run(cmd, label, out); err != nil {
			errs = append(errs, err)
		}
	}
	return errs
}
