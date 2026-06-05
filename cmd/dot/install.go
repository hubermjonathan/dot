package main

import (
	"fmt"
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
		failures += runStep("brew "+strings.Join(mod.Deps.Brew, ", "), "installed", func(out *ui.Step) error {
			return installer.InstallBrew(mod.Deps.Brew, out)
		})
	}

	if len(mod.Apps.Cask) > 0 {
		failures += runStep("cask "+strings.Join(mod.Apps.Cask, ", "), "installed", func(out *ui.Step) error {
			return installer.InstallCask(mod.Apps.Cask, out)
		})
	}

	if len(mod.Provision) > 0 {
		failures += runScriptStep(fmt.Sprintf("provision %d script(s)", len(mod.Provision)), mod.Provision, mod.Interactive, installer.RunProvision)
	}

	return failures
}
