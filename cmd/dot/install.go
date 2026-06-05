package main

import (
	"fmt"
	"os"

	"github.com/hubermjonathan/dotfiles/internal/installer"
	"github.com/hubermjonathan/dotfiles/internal/module"
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

	opts := installer.Options{Verbose: verbose}
	fmt.Println("install")
	var failures int
	for _, mod := range modules {
		failures += installModule(mod, opts)
	}

	if failures > 0 {
		return fmt.Errorf("%d operation(s) failed", failures)
	}
	return nil
}

// installModule runs brew, cask, and provision for one module and returns the
// number of failed operations.
func installModule(mod *module.Module, opts installer.Options) int {
	if len(mod.Deps.Brew) == 0 && len(mod.Apps.Cask) == 0 && len(mod.Provision) == 0 {
		return 0
	}
	modHeader(mod.Name)
	var failures int

	if len(mod.Deps.Brew) > 0 {
		step("brew", joinList(mod.Deps.Brew))
		if err := installer.InstallBrew(mod.Deps.Brew, opts); err != nil {
			resultErr(err.Error())
			dumpCmdError(err, os.Stderr)
			failures++
		} else {
			result(iconOK, "installed")
		}
	}

	if len(mod.Apps.Cask) > 0 {
		step("cask", joinList(mod.Apps.Cask))
		if err := installer.InstallCask(mod.Apps.Cask, opts); err != nil {
			resultErr(err.Error())
			dumpCmdError(err, os.Stderr)
			failures++
		} else {
			result(iconOK, "installed")
		}
	}

	if len(mod.Provision) > 0 {
		step("provision", fmt.Sprintf("%d script(s)", len(mod.Provision)))
		errs := installer.RunProvision(mod.Provision, mod.Interactive, opts)
		if len(errs) == 0 {
			result(iconOK, "ran")
		} else {
			for _, e := range errs {
				resultErr(e.Error())
				dumpCmdError(e, os.Stderr)
			}
			failures += len(errs)
		}
	}

	return failures
}
