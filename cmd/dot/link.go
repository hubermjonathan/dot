package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"

	"github.com/hubermjonathan/dotfiles/internal/installer"
	"github.com/hubermjonathan/dotfiles/internal/linker"
	"github.com/hubermjonathan/dotfiles/internal/module"
	"github.com/hubermjonathan/dotfiles/internal/pathutil"
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
		keys := make([]string, 0, len(mod.Links))
		for k := range mod.Links {
			keys = append(keys, k)
		}
		sort.Strings(keys)
		for _, source := range keys {
			target := mod.Links[source]
			sourcePath := filepath.Join(mod.Path, source)
			targetPath := pathutil.ExpandHome(target)
			backupDir := filepath.Join(pathutil.ExpandHome("~/.dotfiles-backup"), mod.Name)
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
		return fmt.Errorf("%d operation(s) failed", failures)
	}
	return nil
}

// Shared helpers used by all commands

func expandHome(path string) string {
	return pathutil.ExpandHome(path)
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
	out, err := exec.Command("git", "rev-parse", "--show-toplevel").Output()
	if err == nil {
		return strings.TrimSpace(string(out))
	}
	cwd, _ := os.Getwd()
	for d := cwd; d != "/"; d = filepath.Dir(d) {
		if _, err := os.Stat(filepath.Join(d, "modules")); err == nil {
			return d
		}
	}
	return cwd
}
