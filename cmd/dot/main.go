package main

import (
	"os"

	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "dot",
	Short: "Dotfiles management tool",
	RunE: func(cmd *cobra.Command, args []string) error {
		return runInteractive()
	},
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		os.Exit(2)
	}
}
