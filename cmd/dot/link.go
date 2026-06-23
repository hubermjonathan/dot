package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"

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

	fmt.Println("link")
	var failures int
	for _, mod := range modules {
		failures += linkModule(mod)
	}

	if failures > 0 {
		return fmt.Errorf("%d operation(s) failed", failures)
	}
	return nil
}

func linkModule(mod *module.Module) int {
	if len(mod.Links) == 0 && len(mod.PostLink) == 0 {
		return 0
	}
	modHeader(mod.Name)
	var failures int

	if len(mod.Links) > 0 {
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
			res, err := linker.Link(sourcePath, targetPath, backupDir)
			if err != nil {
				resultErr(fmt.Sprintf("%s %s %s: %v", source, iconArrow, target, err))
				failures++
				continue
			}
			switch res {
			case linker.Created:
				result(iconOK, fmt.Sprintf("created  %s %s %s", source, iconArrow, target))
			case linker.Replaced:
				result(iconWarn, fmt.Sprintf("replaced %s %s %s", source, iconArrow, target))
			case linker.Skipped:
				result(iconSkip, fmt.Sprintf("ok       %s %s %s", source, iconArrow, target))
			}
		}
	}

	if len(mod.PostLink) > 0 {
		failures += runScriptsStep(fmt.Sprintf("post_link %d script(s)", len(mod.PostLink)), "ran", "post_link", mod.PostLink, mod.Interactive)
	}

	return failures
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
	var out []*module.Module
	for _, m := range all {
		if filterSet[m.Name] {
			out = append(out, m)
		}
	}
	return out, nil
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

// getMainRepoRoot returns the path of the primary repo checkout, even when
// running from a linked worktree. Used by orphan scanning so it recognizes
// symlinks pointing at either the main checkout or any worktree.
func getMainRepoRoot() string {
	out, err := exec.Command("git", "rev-parse", "--path-format=absolute", "--git-common-dir").Output()
	if err == nil {
		gitDir := strings.TrimSpace(string(out))
		return filepath.Dir(gitDir)
	}
	return getRepoRoot()
}
