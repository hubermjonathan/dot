package main

import (
	"fmt"
	"os"

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
		for source, target := range mod.Links {
			_ = source
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
		os.Exit(1)
	}
	return nil
}
