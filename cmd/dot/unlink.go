package main

import (
	"fmt"
	"os"
	"sort"

	"github.com/hubermjonathan/dotfiles/internal/linker"
	"github.com/spf13/cobra"
)

var unlinkCmd = &cobra.Command{
	Use:   "unlink [module...]",
	Short: "Remove symlinks for modules",
	RunE:  runUnlink,
}

func init() {
	rootCmd.AddCommand(unlinkCmd)
}

func runUnlink(cmd *cobra.Command, args []string) error {
	modules, err := getModules(args)
	if err != nil {
		return err
	}

	var failures int
	for _, mod := range modules {
		fmt.Printf("unlinking %s\n", mod.Name)
		keys := make([]string, 0, len(mod.Links))
		for k := range mod.Links {
			keys = append(keys, k)
		}
		sort.Strings(keys)
		for _, source := range keys {
			target := mod.Links[source]
			targetPath := expandHome(target)
			if err := linker.Unlink(targetPath); err != nil {
				fmt.Fprintf(os.Stderr, "  error: %s: %v\n", source, err)
				failures++
				continue
			}
			fmt.Printf("  removed %s\n", target)
		}
	}

	if failures > 0 {
		return fmt.Errorf("%d operation(s) failed", failures)
	}
	return nil
}
