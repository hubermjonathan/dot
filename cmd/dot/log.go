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

// runStep wraps a subprocess step in a spinner. fn returns the list of errors
// it encountered (empty/nil for success). The captured buffer is dumped on
// failure (always) and on success when --verbose is set. Returns the failure
// count. A panic inside fn still triggers Done via defer so the spinner
// goroutine never leaks.
func runStep(label, doneStatus string, fn func(*ui.Step) []error) int {
	step := ui.Start(label)
	var errs []error
	func() {
		defer func() {
			if r := recover(); r != nil {
				step.Done(iconErr, "failed", true)
				panic(r)
			}
		}()
		errs = fn(step)
	}()
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

// runInteractiveStep skips the spinner so subprocess stdout/stderr stream
// directly to the terminal. Used for `setup.interactive = true` modules where
// the user must see prompts (auth flows, sudo, etc.). fn writes its output
// directly to os.Stdout / os.Stderr.
func runInteractiveStep(label, doneStatus string, fn func(out io.Writer) []error) int {
	fmt.Printf("    %s\n", label)
	errs := fn(os.Stdout)
	if len(errs) > 0 {
		for _, e := range errs {
			resultErr(e.Error())
		}
		return len(errs)
	}
	result(iconOK, fmt.Sprintf("%s — %s", label, doneStatus))
	return 0
}
