package main

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
)

var initCmd = &cobra.Command{
	Use:   "init <name>",
	Short: "Scaffold a new module",
	Args:  cobra.ExactArgs(1),
	RunE:  runInit,
}

func init() {
	rootCmd.AddCommand(initCmd)
}

func runInit(cmd *cobra.Command, args []string) error {
	name := args[0]
	modulesDir := filepath.Join(getRepoRoot(), "modules")
	dir := filepath.Join(modulesDir, name)

	if _, err := os.Stat(dir); err == nil {
		return fmt.Errorf("module %q already exists", name)
	}

	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}

	toml := fmt.Sprintf(`[module]
name = %q
description = ""

[links]

[deps]
brew = []

[apps]
cask = []
`, name)

	if err := os.WriteFile(filepath.Join(dir, "module.toml"), []byte(toml), 0644); err != nil {
		return err
	}

	fmt.Printf("created modules/%s/module.toml\n", name)
	return nil
}
