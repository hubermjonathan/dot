package main

import (
	"fmt"
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

// runStep wraps a subprocess step in a spinner. fn returns the list of errors
// it encountered (empty/nil for success). The step renders as a spinner while
// fn runs; the captured buffer is dumped on failure (always) and on success
// when --verbose is set. Returns the failure count.
func runStep(label, doneStatus string, fn func(*ui.Step) []error) int {
	step := ui.Start(label)
	errs := fn(step)
	if len(errs) > 0 {
		step.Done(iconErr, "failed", true)
		for _, e := range errs {
			resultErr(e.Error())
		}
		return len(errs)
	}
	step.Done(iconOK, doneStatus, verbose)
	return 0
}
