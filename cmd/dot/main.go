package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "dot",
	Short: "Dotfiles management tool",
	RunE: func(cmd *cobra.Command, args []string) error {
		fmt.Println("interactive mode not yet implemented")
		return nil
	},
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		os.Exit(2)
	}
}
