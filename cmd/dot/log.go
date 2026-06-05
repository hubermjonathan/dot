package main

import (
	"fmt"
	"io"
	"os"

	"github.com/hubermjonathan/dotfiles/internal/ui"
)

// Console output icons.
const (
	iconOK    = "✓"
	iconWarn  = "!"
	iconErr   = "✗"
	iconSkip  = "·"
	iconArrow = "→"
)

// modHeader prints a `▸ module` heading for a module section.
func modHeader(name string) {
	fmt.Printf("\n▸ %s\n", name)
}

// result prints `    icon msg` two-space indented under a step heading.
func result(icon, msg string) {
	fmt.Printf("    %s %s\n", icon, msg)
}

// resultErr writes a failure message to stderr at the same indent as result.
func resultErr(msg string) {
	fmt.Fprintf(os.Stderr, "    %s %s\n", iconErr, msg)
}

// runStep wraps a single subprocess step in a spinner. It returns 1 on failure
// and 0 on success. The full captured buffer is dumped on failure (always) and
// on success when --verbose is set.
func runStep(label, doneStatus string, do func(*ui.Step) error) int {
	step := ui.Start(label)
	err := do(step)
	if err != nil {
		step.Done(iconErr, "failed", true)
		fmt.Fprintf(os.Stderr, "    %s %v\n", iconErr, err)
		return 1
	}
	step.Done(iconOK, doneStatus, verbose)
	return 0
}

// runScriptStep runs a list of shell scripts as a single spinner step. fn is
// either installer.RunProvision or installer.RunPostLink.
func runScriptStep(label string, scripts []string, interactive bool, fn func([]string, bool, io.Writer) []error) int {
	step := ui.Start(label)
	errs := fn(scripts, interactive, step)
	if len(errs) > 0 {
		step.Done(iconErr, "failed", true)
		for _, e := range errs {
			fmt.Fprintf(os.Stderr, "    %s %v\n", iconErr, e)
		}
		return len(errs)
	}
	step.Done(iconOK, "ran", verbose)
	return 0
}
