package main

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/hubermjonathan/dotfiles/internal/installer"
	"github.com/hubermjonathan/dotfiles/internal/linker"
	"github.com/hubermjonathan/dotfiles/internal/module"
	"github.com/spf13/cobra"
)

var linkCmd = &cobra.Command{
	Use:   "link [module...]",
	Short: "Create symlinks for modules",
	RunE:  runLink,
}

func init() {
	rootCmd.AddCommand(linkCmd)
}

func runLink(cmd *cobra.Command, args []string) error {
	modules, err := getModules(args)
	if err != nil {
		return err
	}

	var failures int
	for _, mod := range modules {
		fmt.Printf("linking %s\n", mod.Name)
		for source, target := range mod.Links {
			sourcePath := filepath.Join(mod.Path, source)
			targetPath := expandHome(target)
			backupDir := filepath.Join(expandHome("~/.dotfiles-backup"), mod.Name)
			result, err := linker.Link(sourcePath, targetPath, backupDir)
			if err != nil {
				fmt.Fprintf(os.Stderr, "  error: %s → %s: %v\n", source, target, err)
				failures++
				continue
			}
			switch result {
			case linker.Created:
				fmt.Printf("  created %s → %s\n", source, target)
			case linker.Replaced:
				fmt.Printf("  replaced %s → %s (backed up)\n", source, target)
			case linker.Skipped:
				fmt.Printf("  ok %s → %s\n", source, target)
			}
		}
		if errs := installer.RunPostLink(mod.PostLink); len(errs) > 0 {
			for _, e := range errs {
				fmt.Fprintf(os.Stderr, "  warning: %v\n", e)
			}
		}
	}

	if failures > 0 {
		os.Exit(1)
	}
	return nil
}

// Shared helpers used by all commands

func expandHome(path string) string {
	if len(path) > 1 && path[:2] == "~/" {
		home, _ := os.UserHomeDir()
		return home + path[1:]
	}
	return path
}

func getModules(filter []string) ([]*module.Module, error) {
	modulesDir := filepath.Join(getRepoRoot(), "modules")
	all, err := module.Discover(modulesDir)
	if err != nil {
		return nil, err
	}
	if len(filter) == 0 {
		return all, nil
	}
	filterSet := make(map[string]bool)
	for _, f := range filter {
		filterSet[f] = true
	}
	var result []*module.Module
	for _, m := range all {
		if filterSet[m.Name] {
			result = append(result, m)
		}
	}
	return result, nil
}

func getRepoRoot() string {
	exe, _ := os.Executable()
	dir := filepath.Dir(exe)
	for d := dir; d != "/"; d = filepath.Dir(d) {
		if _, err := os.Stat(filepath.Join(d, "modules")); err == nil {
			return d
		}
	}
	cwd, _ := os.Getwd()
	return cwd
}
