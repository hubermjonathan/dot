package main

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/hubermjonathan/dotfiles/internal/doctor"
	"github.com/hubermjonathan/dotfiles/internal/linker"
	"github.com/hubermjonathan/dotfiles/internal/module"
	"github.com/spf13/cobra"
)

var (
	fixFlag     bool
	orphansFlag bool
)

var doctorCmd = &cobra.Command{
	Use:   "doctor",
	Short: "Health check all modules",
	RunE:  runDoctor,
}

func init() {
	doctorCmd.Flags().BoolVar(&fixFlag, "fix", false, "Auto-fix issues")
	doctorCmd.Flags().BoolVar(&orphansFlag, "orphans", false, "Walk for stale repo symlinks (slow, ~10-15s)")
	rootCmd.AddCommand(doctorCmd)
}

func runDoctor(cmd *cobra.Command, args []string) error {
	modules, err := getModules(nil)
	if err != nil {
		return err
	}

	if orphansFlag {
		return runOrphans(modules)
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

func runOrphans(modules []*module.Module) error {
	declared := map[string]bool{}
	for _, m := range modules {
		for _, tgt := range m.Links {
			declared[expandHome(tgt)] = true
		}
	}

	home, err := os.UserHomeDir()
	if err != nil {
		return err
	}
	roots := []string{
		home,
		filepath.Join(home, ".config"),
		filepath.Join(home, ".claude"),
		filepath.Join(home, "Library", "Preferences"),
		filepath.Join(home, "Library", "Application Support"),
	}

	repoRoot := getMainRepoRoot()
	orphans, err := linker.FindOrphans(roots, repoRoot, declared)
	if err != nil {
		return err
	}

	if len(orphans) == 0 {
		fmt.Println("no orphans")
		return nil
	}

	fmt.Println("orphans:")
	for _, o := range orphans {
		fmt.Printf("  %s → %s\n", o.Path, o.Target)
	}

	if !fixFlag {
		fmt.Printf("\n%d orphan(s). Run with --fix to remove.\n", len(orphans))
		os.Exit(1)
	}

	var failed int
	for _, o := range orphans {
		if err := linker.RemoveOrphan(o); err != nil {
			fmt.Fprintf(os.Stderr, "  ✗ %s: %v\n", o.Path, err)
			failed++
		} else {
			fmt.Printf("  ✓ removed %s\n", o.Path)
		}
	}
	fmt.Printf("\nremoved: %d, failed: %d\n", len(orphans)-failed, failed)
	if failed > 0 {
		os.Exit(1)
	}
	return nil
}
