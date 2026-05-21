package installer

import (
	"fmt"
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

func InstallBrew(formulae []string) error {
	if len(formulae) == 0 {
		return nil
	}
	args := BuildBrewArgs(formulae)
	cmd := exec.Command("brew", args...)
	cmd.Stdout = nil
	cmd.Stderr = nil
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("brew install failed: %w", err)
	}
	return nil
}

func InstallCask(casks []string) error {
	if len(casks) == 0 {
		return nil
	}
	args := BuildCaskArgs(casks)
	cmd := exec.Command("brew", args...)
	cmd.Stdout = nil
	cmd.Stderr = nil
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("brew cask install failed: %w", err)
	}
	return nil
}

func runCommands(commands []string, label string, interactive bool) []error {
	var errs []error
	for _, c := range commands {
		cmd := exec.Command("sh", "-c", c)
		if interactive {
			cmd.Stdin = os.Stdin
			cmd.Stdout = os.Stdout
			cmd.Stderr = os.Stderr
		}
		if err := cmd.Run(); err != nil {
			errs = append(errs, fmt.Errorf("%s %q failed: %w", label, c, err))
		}
	}
	return errs
}

func RunProvision(commands []string, interactive bool) []error {
	return runCommands(commands, "provision", interactive)
}

func RunPostLink(commands []string, interactive bool) []error {
	return runCommands(commands, "post_link", interactive)
}
