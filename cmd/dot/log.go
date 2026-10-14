package main

import (
	"fmt"
	"os"
	"time"

	"github.com/hubermjonathan/dotfiles/internal/installer"
	"github.com/hubermjonathan/dotfiles/internal/module"
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

// reportErrs prints each error via resultErr and returns the count.
func reportErrs(errs []error) int {
	for _, e := range errs {
		resultErr(e.Error())
	}
	return len(errs)
}

// runStep wraps a subprocess step in a spinner. fn returns the list of errors
// it encountered (empty/nil for success). The captured buffer is dumped on
// failure (always) and on success when --verbose is set. A panic inside fn
// still finalises the spinner via the deferred Done so the goroutine never
// leaks. Returns the failure count.
func runStep(label, doneStatus string, fn func(*ui.Step) []error) int {
	step := ui.Start(label)
	defer step.Done(iconErr, "failed", true) // idempotent — only fires on panic
	errs := fn(step)
	if len(errs) > 0 {
		step.Done(iconErr, "failed", true)
		return reportErrs(errs)
	}
	step.Done(iconOK, doneStatus, verbose)
	return 0
}

// runScriptsStep runs an installer script list (provision / post_link).
// Non-interactive scripts buffer behind the spinner. Interactive scripts run on
// the terminal itself, so prompts such as auth flows and sudo work, and end on
// the same status row as runStep.
func runScriptsStep(label, doneStatus, kind string, scripts []module.Step, interactive bool) int {
	if !interactive {
		return runStep(label, doneStatus, func(s *ui.Step) []error {
			return installer.RunScripts(scripts, kind, false, s)
		})
	}
	fmt.Printf("    %s\n", label)
	started := time.Now()
	errs := installer.RunScripts(scripts, kind, true, nil)
	elapsed := time.Since(started).Round(100 * time.Millisecond)
	if len(errs) > 0 {
		result(iconErr, fmt.Sprintf("%s — failed (%s)", label, elapsed))
		return reportErrs(errs)
	}
	result(iconOK, fmt.Sprintf("%s — %s (%s)", label, doneStatus, elapsed))
	return 0
}
