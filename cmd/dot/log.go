package main

import (
	"bytes"
	"fmt"
	"io"
	"os"

	"github.com/hubermjonathan/dotfiles/internal/installer"
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

// runScriptsStep runs an installer script list (provision / post_link),
// picking spinner-vs-passthrough based on mod.Interactive. Interactive scripts
// stream stdout/stderr directly so prompts (auth flows, sudo) are visible;
// non-interactive scripts buffer behind the spinner.
func runScriptsStep(label, doneStatus, kind string, scripts []string, interactive bool) int {
	if !interactive {
		return runStep(label, doneStatus, func(s *ui.Step) []error {
			return installer.RunScripts(scripts, kind, false, s)
		})
	}
	fmt.Printf("    %s\n", label)
	out := &indentWriter{w: os.Stdout, prefix: "      ", atLineStart: true}
	if errs := installer.RunScripts(scripts, kind, true, out); len(errs) > 0 {
		return reportErrs(errs)
	}
	result(iconOK, fmt.Sprintf("%s — %s", label, doneStatus))
	return 0
}

// indentWriter prefixes every line written through it with prefix. Tracks
// whether the next byte starts a new line so prefixes don't double up across
// chunked writes. Not safe for concurrent use.
type indentWriter struct {
	w           io.Writer
	prefix      string
	atLineStart bool
}

func (iw *indentWriter) Write(p []byte) (int, error) {
	written := 0
	for len(p) > 0 {
		if iw.atLineStart {
			if _, err := io.WriteString(iw.w, iw.prefix); err != nil {
				return written, err
			}
			iw.atLineStart = false
		}
		nl := bytes.IndexByte(p, '\n')
		if nl < 0 {
			n, err := iw.w.Write(p)
			return written + n, err
		}
		n, err := iw.w.Write(p[:nl+1])
		written += n
		if err != nil {
			return written, err
		}
		iw.atLineStart = true
		p = p[nl+1:]
	}
	return written, nil
}
