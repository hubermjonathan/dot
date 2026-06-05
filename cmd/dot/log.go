package main

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"time"

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
	return runInteractiveStep(label, doneStatus, func(out io.Writer) []error {
		return installer.RunScripts(scripts, kind, true, out)
	})
}

// runInteractiveStep runs fn with an indenting writer over os.Stdout so
// subprocess output streams live (prompts visible). It mirrors runStep's
// final-line formatting (icon + label + status + elapsed) and panic safety,
// without the spinner. fn writes to out; the writer ensures every line is
// six-space indented to align under the step header. If the subprocess leaves
// the cursor mid-line (no trailing newline) a synthetic newline is emitted
// before the footer so it doesn't glue onto the last output line.
func runInteractiveStep(label, doneStatus string, fn func(io.Writer) []error) int {
	fmt.Printf("    %s\n", label)
	started := time.Now()
	iw := &indentWriter{w: os.Stdout, prefix: "      ", atLineStart: true}
	footerEmitted := false
	defer func() {
		if !footerEmitted {
			ensureNewline(iw)
			elapsed := time.Since(started).Round(100 * time.Millisecond)
			result(iconErr, fmt.Sprintf("%s — failed (%s)", label, elapsed))
		}
	}()
	errs := fn(iw)
	ensureNewline(iw)
	elapsed := time.Since(started).Round(100 * time.Millisecond)
	if len(errs) > 0 {
		result(iconErr, fmt.Sprintf("%s — failed (%s)", label, elapsed))
		footerEmitted = true
		return reportErrs(errs)
	}
	result(iconOK, fmt.Sprintf("%s — %s (%s)", label, doneStatus, elapsed))
	footerEmitted = true
	return 0
}

// ensureNewline writes a newline to iw's underlying writer if the last byte
// emitted wasn't already a newline, so subsequent footer lines start on a
// fresh row.
func ensureNewline(iw *indentWriter) {
	if !iw.atLineStart {
		fmt.Fprintln(iw.w)
		iw.atLineStart = true
	}
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
