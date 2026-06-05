package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"

	"github.com/hubermjonathan/dotfiles/internal/linker"
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
		linked, broken, missing, diverged := 0, 0, 0, 0
		total := len(mod.Links)
		keys := make([]string, 0, len(mod.Links))
		for k := range mod.Links {
			keys = append(keys, k)
		}
		sort.Strings(keys)

		type linkDetail struct {
			source, target string
			status         linker.Status
		}
		var details []linkDetail

		for _, source := range keys {
			target := mod.Links[source]
			sourcePath := filepath.Join(mod.Path, source)
			targetPath := expandHome(target)
			status := linker.Verify(sourcePath, targetPath)

			detail := linkDetail{source: source, target: target, status: status}

			switch status {
			case linker.StatusOK:
				linked++
			case linker.StatusBroken, linker.StatusWrongTarget:
				broken++
			case linker.StatusNotSymlink:
				diverged++
			default:
				missing++
			}
			details = append(details, detail)
		}

		state := "unlinked"
		if total == 0 {
			state = "no-links"
		} else if linked == total {
			state = "linked"
		} else if broken > 0 {
			state = "broken"
		} else if diverged > 0 {
			state = "diverged"
		} else if linked > 0 {
			state = "partial"
		}

		fmt.Printf("%-12s [%s] %s\n", mod.Name, state, mod.Description)

		if diffFlag {
			for _, d := range details {
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
