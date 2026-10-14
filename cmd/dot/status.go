package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"

	"github.com/hubermjonathan/dotfiles/internal/linker"
	"github.com/hubermjonathan/dotfiles/internal/module"
	"github.com/spf13/cobra"
)

var diffFlag bool

var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "Show module states",
	RunE:  runStatus,
}

func init() {
	statusCmd.Flags().BoolVar(&diffFlag, "diff", false, "Show diffs for diverged files")
	rootCmd.AddCommand(statusCmd)
}

func runStatus(cmd *cobra.Command, args []string) error {
	modules, err := getModules(args)
	if err != nil {
		return err
	}

	for _, mod := range modules {
		state, links := moduleState(mod)
		fmt.Printf("%-12s [%s] %s\n", mod.Name, state, mod.Description)

		if diffFlag {
			for _, d := range links {
				sourcePath := filepath.Join(mod.Path, d.source)
				targetPath := expandHome(d.target)
				switch d.status {
				case linker.StatusOK:
					fmt.Printf("  ✓ %s\n", d.source)
				case linker.StatusMissing:
					fmt.Printf("  ✗ %s → %s (missing)\n", d.source, d.target)
				case linker.StatusBroken:
					fmt.Printf("  ✗ %s → %s (broken)\n", d.source, d.target)
				case linker.StatusWrongTarget:
					fmt.Printf("  ✗ %s → %s (wrong target)\n", d.source, d.target)
				case linker.StatusNotSymlink:
					if filesIdentical(sourcePath, targetPath) {
						fmt.Printf("  ~ %s → %s (not linked, identical)\n", d.source, d.target)
					} else {
						fmt.Printf("  ≠ %s → %s (diverged)\n", d.source, d.target)
						printDiff(sourcePath, targetPath)
					}
				}
			}
			fmt.Println()
		}
	}
	return nil
}

type linkStatus struct {
	source, target string
	status         linker.Status
}

// moduleState verifies each of the module's links, in source order, and sums
// them into one state for `dot status` and the picker.
func moduleState(mod *module.Module) (string, []linkStatus) {
	keys := make([]string, 0, len(mod.Links))
	for k := range mod.Links {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	var links []linkStatus
	linked, broken, diverged := 0, 0, 0
	for _, source := range keys {
		target := mod.Links[source]
		status := linker.Verify(filepath.Join(mod.Path, source), expandHome(target))
		links = append(links, linkStatus{source: source, target: target, status: status})
		switch status {
		case linker.StatusOK:
			linked++
		case linker.StatusBroken, linker.StatusWrongTarget:
			broken++
		case linker.StatusNotSymlink:
			diverged++
		}
	}

	switch {
	case len(links) == 0:
		return "no-links", links
	case linked == len(links):
		return "linked", links
	case broken > 0:
		return "broken", links
	case diverged > 0:
		return "diverged", links
	case linked > 0:
		return "partial", links
	}
	return "unlinked", links
}

func filesIdentical(a, b string) bool {
	contentA, errA := os.ReadFile(a)
	contentB, errB := os.ReadFile(b)
	if errA != nil || errB != nil {
		return false
	}
	return bytes.Equal(contentA, contentB)
}

func printDiff(repoFile, machineFile string) {
	cmd := exec.Command("diff", "--color=always", "-u", repoFile, machineFile)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Run()
}
