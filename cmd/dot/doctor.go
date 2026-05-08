package main

import (
	"fmt"
	"os"

	"github.com/hubermjonathan/dotfiles/internal/doctor"
	"github.com/spf13/cobra"
)

var fixFlag bool

var doctorCmd = &cobra.Command{
	Use:   "doctor",
	Short: "Health check all modules",
	RunE:  runDoctor,
}

func init() {
	doctorCmd.Flags().BoolVar(&fixFlag, "fix", false, "Auto-fix issues")
	rootCmd.AddCommand(doctorCmd)
}

func runDoctor(cmd *cobra.Command, args []string) error {
	modules, err := getModules(nil)
	if err != nil {
		return err
	}

	var allIssues []doctor.Issue
	for _, mod := range modules {
		issues := doctor.Check(mod)
		allIssues = append(allIssues, issues...)
	}

	if len(allIssues) == 0 {
		fmt.Println("all healthy")
		return nil
	}

	var fixed, failed int
	currentModule := ""
	for _, issue := range allIssues {
		if issue.Module != currentModule {
			fmt.Printf("\n%s:\n", issue.Module)
			currentModule = issue.Module
		}
		if fixFlag && issue.FixAction != nil {
			if err := issue.FixAction(); err != nil {
				fmt.Fprintf(os.Stderr, "  ✗ %s [%s]: %v\n", issue.Description, issue.Type, err)
				failed++
			} else {
				fmt.Printf("  ✓ fixed: %s [%s]\n", issue.Description, issue.Type)
				fixed++
			}
		} else if issue.FixAction != nil {
			fmt.Printf("  • %s [%s] — fixable with --fix\n", issue.Description, issue.Type)
		} else {
			fmt.Printf("  • %s [%s] — manual fix needed\n", issue.Description, issue.Type)
		}
	}

	if fixFlag {
		fmt.Printf("\nfixed: %d, failed: %d\n", fixed, failed)
	}

	if failed > 0 || (!fixFlag && len(allIssues) > 0) {
		os.Exit(1)
	}
	return nil
}
