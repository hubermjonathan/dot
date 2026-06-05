// Package ui renders a single-line spinner that displays a step label and the
// most recent line of streamed subprocess output. It degrades to plain status
// lines when stdout is not a TTY so output stays pipe-friendly.
package ui

import (
	"fmt"
	"io"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/mattn/go-isatty"
)

const (
	frameInterval = 80 * time.Millisecond
	clearLine     = "\r\033[2K"
	tailMaxRunes  = 60
)

var frames = []rune("⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏")

// Step is a live spinner row. It buffers every line written through Write so
// the full output can be replayed on failure or when verbose mode is on.
type Step struct {
	label   string
	out     io.Writer
	tty     bool
	mu      sync.Mutex
	tail    string
	buf     strings.Builder
	stopCh  chan struct{}
	doneCh  chan struct{}
	started time.Time
	frame   int
}

// Start prints an opening spinner line for label and returns a Step that the
// caller writes subprocess output into.
func Start(label string) *Step {
	out := os.Stdout
	tty := isatty.IsTerminal(out.Fd())
	s := &Step{
		label:   label,
		out:     out,
		tty:     tty,
		stopCh:  make(chan struct{}),
		doneCh:  make(chan struct{}),
		started: time.Now(),
	}
	if tty {
		go s.loop()
	} else {
		fmt.Fprintf(out, "    %s\n", label)
		close(s.doneCh)
	}
	return s
}

func (s *Step) loop() {
	defer close(s.doneCh)
	t := time.NewTicker(frameInterval)
	defer t.Stop()
	for {
		select {
		case <-s.stopCh:
			return
		case <-t.C:
			s.render()
		}
	}
}

func (s *Step) render() {
	s.mu.Lock()
	defer s.mu.Unlock()
	frame := frames[s.frame%len(frames)]
	s.frame++
	tail := s.tail
	if tail == "" {
		fmt.Fprintf(s.out, "%s    %c %s", clearLine, frame, s.label)
		return
	}
	fmt.Fprintf(s.out, "%s    %c %s — %s", clearLine, frame, s.label, truncate(tail, tailMaxRunes))
}

// Write satisfies io.Writer. Each newline-terminated line updates the spinner
// tail and is appended to the replay buffer.
func (s *Step) Write(p []byte) (int, error) {
	s.mu.Lock()
	s.buf.Write(p)
	for _, line := range splitLines(p) {
		s.tail = line
	}
	s.mu.Unlock()
	return len(p), nil
}

// Done finalises the step. icon is the leading status glyph (✓, ✗, ·).
// status is the brief result text. dumpBuffer prints the captured output below
// the final line; use it for failures or when verbose mode is on.
func (s *Step) Done(icon, status string, dumpBuffer bool) {
	if s.tty {
		close(s.stopCh)
		<-s.doneCh
		fmt.Fprint(s.out, clearLine)
	}
	elapsed := time.Since(s.started).Round(100 * time.Millisecond)
	fmt.Fprintf(s.out, "    %s %s — %s (%s)\n", icon, s.label, status, elapsed)
	if dumpBuffer {
		s.replay(s.out)
	}
}

// Buffer returns everything written through the spinner.
func (s *Step) Buffer() string {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.buf.String()
}

// Replay writes the captured buffer to w, indented for visual nesting.
func (s *Step) Replay(w io.Writer) { s.replay(w) }

func (s *Step) replay(w io.Writer) {
	out := strings.TrimRight(s.Buffer(), "\n")
	if out == "" {
		return
	}
	for _, line := range strings.Split(out, "\n") {
		fmt.Fprintf(w, "      %s\n", line)
	}
}

func splitLines(p []byte) []string {
	if len(p) == 0 {
		return nil
	}
	raw := strings.Split(strings.TrimRight(string(p), "\n"), "\n")
	out := make([]string, 0, len(raw))
	for _, l := range raw {
		l = strings.TrimSpace(l)
		if l != "" {
			out = append(out, l)
		}
	}
	return out
}

func truncate(s string, max int) string {
	r := []rune(s)
	if len(r) <= max {
		return s
	}
	return string(r[:max-1]) + "…"
}
