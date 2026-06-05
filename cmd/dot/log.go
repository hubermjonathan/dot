package main

import (
	"errors"
	"fmt"
	"io"
	"os"
	"strings"

	"github.com/hubermjonathan/dotfiles/internal/installer"
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

// step prints a sub-action heading under a module.
func step(label string, detail string) {
	if detail == "" {
		fmt.Printf("  %s\n", label)
		return
	}
	fmt.Printf("  %s %s\n", label, detail)
}

// result prints `    icon msg` two-space indented under a step heading.
func result(icon, msg string) {
	fmt.Printf("    %s %s\n", icon, msg)
}

// resultErr writes a failure message to stderr at the same indent as result.
func resultErr(msg string) {
	fmt.Fprintf(os.Stderr, "    %s %s\n", iconErr, msg)
}

// dumpCmdError prints the captured output of a failed installer command at an
// extra indent so it stays visually associated with its result line.
func dumpCmdError(err error, w io.Writer) {
	var ce *installer.CommandError
	if !errors.As(err, &ce) || ce.Output == "" {
		return
	}
	for _, line := range strings.Split(strings.TrimRight(ce.Output, "\n"), "\n") {
		fmt.Fprintf(w, "      %s\n", line)
	}
}

// joinList joins a list of strings into "a, b, c" or returns "—" when empty.
func joinList(xs []string) string {
	if len(xs) == 0 {
		return "—"
	}
	return strings.Join(xs, ", ")
}
