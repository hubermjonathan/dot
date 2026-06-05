package main

import (
	"fmt"
	"io"
	"strings"

	"github.com/hubermjonathan/dotfiles/internal/installer"
	"github.com/hubermjonathan/dotfiles/internal/module"
	"github.com/hubermjonathan/dotfiles/internal/ui"
	"github.com/spf13/cobra"
)

var installCmd = &cobra.Command{
	Use:   "install [module...]",
	Short: "Install brew deps and apps for modules",
	RunE:  runInstall,
}

func init() {
	rootCmd.AddCommand(installCmd)
}

func runInstall(cmd *cobra.Command, args []string) error {
	modules, err := getModules(args)
	if err != nil {
		return err
	}

	fmt.Println("install")
	var failures int
	for _, mod := range modules {
		failures += installModule(mod)
	}

	if failures > 0 {
		return fmt.Errorf("%d operation(s) failed", failures)
	}
	return nil
}

func installModule(mod *module.Module) int {
	if len(mod.Deps.Brew) == 0 && len(mod.Apps.Cask) == 0 && len(mod.Provision) == 0 {
		return 0
	}
	modHeader(mod.Name)
	var failures int

	if len(mod.Deps.Brew) > 0 {
		failures += runStep("brew "+strings.Join(mod.Deps.Brew, ", "), "installed", func(s *ui.Step) []error {
			return errSlice(installer.InstallBrew(mod.Deps.Brew, s))
		})
	}

	if len(mod.Apps.Cask) > 0 {
		failures += runStep("cask "+strings.Join(mod.Apps.Cask, ", "), "installed", func(s *ui.Step) []error {
			return errSlice(installer.InstallCask(mod.Apps.Cask, s))
		})
	}

	if len(mod.Provision) > 0 {
		label := fmt.Sprintf("provision %d script(s)", len(mod.Provision))
		if mod.Interactive {
			failures += runInteractiveStep(label, "ran", func(out io.Writer) []error {
				return installer.RunScripts(mod.Provision, "provision", true, out)
			})
		} else {
			failures += runStep(label, "ran", func(s *ui.Step) []error {
				return installer.RunScripts(mod.Provision, "provision", false, s)
			})
		}
	}

	return failures
}

// errSlice wraps a single error into a one-element slice (or nil) so single-
// command callers can share the runStep []error contract.
func errSlice(err error) []error {
	if err == nil {
		return nil
	}
	return []error{err}
}
