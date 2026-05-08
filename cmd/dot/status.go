package main

import (
	"fmt"
	"path/filepath"

	"github.com/hubermjonathan/dotfiles/internal/linker"
	"github.com/spf13/cobra"
)

var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "Show module states",
	RunE:  runStatus,
}

func init() {
	rootCmd.AddCommand(statusCmd)
}

func runStatus(cmd *cobra.Command, args []string) error {
	modules, err := getModules(nil)
	if err != nil {
		return err
	}

	for _, mod := range modules {
		linked, broken, missing := 0, 0, 0
		total := len(mod.Links)
		for source, target := range mod.Links {
			sourcePath := filepath.Join(mod.Path, source)
			targetPath := expandHome(target)
			status := linker.Verify(sourcePath, targetPath)
			switch status {
			case linker.StatusOK:
				linked++
			case linker.StatusBroken, linker.StatusWrongTarget:
				broken++
			default:
				missing++
			}
		}

		state := "unlinked"
		if linked == total && total > 0 {
			state = "linked"
		} else if broken > 0 {
			state = "broken"
		} else if linked > 0 {
			state = "partial"
		}

		fmt.Printf("%-12s [%s] %s\n", mod.Name, state, mod.Description)
	}
	return nil
}
