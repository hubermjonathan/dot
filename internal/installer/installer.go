package installer

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// Options control how installer commands stream their output.
//
// When Verbose is true, child stdout/stderr stream directly to os.Stdout/os.Stderr.
// When false, output is captured; on failure the captured buffer is returned in
// the error so callers can decide how to surface it.
type Options struct {
	Verbose bool
}

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

// CommandError carries the captured stdout+stderr of a non-verbose command run
// so callers can choose to print it on failure.
type CommandError struct {
	Label  string
	Cmd    string
	Err    error
	Output string
}

func (e *CommandError) Error() string {
	if e.Output == "" {
		return fmt.Sprintf("%s failed: %v", e.Label, e.Err)
	}
	return fmt.Sprintf("%s failed: %v\n%s", e.Label, e.Err, e.Output)
}

func (e *CommandError) Unwrap() error { return e.Err }

func runCommand(cmd *exec.Cmd, label, cmdStr string, opts Options) error {
	var buf bytes.Buffer
	if opts.Verbose {
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
	} else {
		cmd.Stdout = &buf
		cmd.Stderr = &buf
	}
	if err := cmd.Run(); err != nil {
		return &CommandError{Label: label, Cmd: cmdStr, Err: err, Output: buf.String()}
	}
	return nil
}

func InstallBrew(formulae []string, opts Options) error {
	if len(formulae) == 0 {
		return nil
	}
	args := BuildBrewArgs(formulae)
	cmd := exec.Command("brew", args...)
	return runCommand(cmd, "brew install", "brew "+strings.Join(args, " "), opts)
}

func InstallCask(casks []string, opts Options) error {
	if len(casks) == 0 {
		return nil
	}
	args := BuildCaskArgs(casks)
	cmd := exec.Command("brew", args...)
	return runCommand(cmd, "brew install --cask", "brew "+strings.Join(args, " "), opts)
}

func runScripts(commands []string, label string, interactive bool, opts Options) []error {
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
		if err := runCommand(cmd, label, c, opts); err != nil {
			errs = append(errs, err)
		}
	}
	return errs
}

func RunProvision(commands []string, interactive bool, opts Options) []error {
	return runScripts(commands, "provision", interactive, opts)
}

func RunPostLink(commands []string, interactive bool, opts Options) []error {
	return runScripts(commands, "post_link", interactive, opts)
}
