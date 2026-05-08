package main

import (
	"fmt"
	"os"

	"github.com/hubermjonathan/dotfiles/internal/installer"
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

	var failures int
	for _, mod := range modules {
		fmt.Printf("installing %s\n", mod.Name)
		if err := installer.InstallBrew(mod.Deps.Brew); err != nil {
			fmt.Fprintf(os.Stderr, "  error: %v\n", err)
			failures++
		}
		if err := installer.InstallCask(mod.Apps.Cask); err != nil {
			fmt.Fprintf(os.Stderr, "  error: %v\n", err)
			failures++
		}
		if errs := installer.RunProvision(mod.Provision); len(errs) > 0 {
			for _, e := range errs {
				fmt.Fprintf(os.Stderr, "  error: %v\n", e)
				failures++
			}
		}
	}

	if failures > 0 {
		return fmt.Errorf("%d operation(s) failed", failures)
	}
	return nil
}
