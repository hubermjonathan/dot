package installer

import (
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"
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

// CommandError reports a failed subprocess. Cmd is the rendered shell command
// for diagnostics; Err is the underlying os/exec error.
type CommandError struct {
	Label string
	Cmd   string
	Err   error
}

func (e *CommandError) Error() string {
	return fmt.Sprintf("%s failed: %v", e.Label, e.Err)
}

func (e *CommandError) Unwrap() error { return e.Err }

// Run executes cmd with stdout+stderr both routed to out and returns a
// CommandError on failure. Callers (e.g. ui.Step) own the buffer.
func Run(cmd *exec.Cmd, label, cmdStr string, out io.Writer) error {
	cmd.Stdout = out
	cmd.Stderr = out
	if err := cmd.Run(); err != nil {
		return &CommandError{Label: label, Cmd: cmdStr, Err: err}
	}
	return nil
}

func InstallBrew(formulae []string, out io.Writer) error {
	if len(formulae) == 0 {
		return nil
	}
	args := BuildBrewArgs(formulae)
	return Run(exec.Command("brew", args...), "brew install", "brew "+strings.Join(args, " "), out)
}

func InstallCask(casks []string, out io.Writer) error {
	if len(casks) == 0 {
		return nil
	}
	args := BuildCaskArgs(casks)
	return Run(exec.Command("brew", args...), "brew install --cask", "brew "+strings.Join(args, " "), out)
}

// RunScripts runs each command with `sh -c`. When interactive is true the
// child inherits the controlling terminal so prompts work; out is ignored in
// that case. Otherwise stdout+stderr are routed to out.
func RunScripts(commands []string, label string, interactive bool, out io.Writer) []error {
	var errs []error
	for _, c := range commands {
		cmd := exec.Command("sh", "-c", c)
		if interactive {
			cmd.Stdin = os.Stdin
			cmd.Stdout = os.Stdout
			cmd.Stderr = os.Stderr
			if err := cmd.Run(); err != nil {
				errs = append(errs, &CommandError{Label: label, Cmd: c, Err: err})
			}
			continue
		}
		if err := Run(cmd, label, c, out); err != nil {
			errs = append(errs, err)
		}
	}
	return errs
}

func RunProvision(commands []string, interactive bool, out io.Writer) []error {
	return RunScripts(commands, "provision", interactive, out)
}

func RunPostLink(commands []string, interactive bool, out io.Writer) []error {
	return RunScripts(commands, "post_link", interactive, out)
}
