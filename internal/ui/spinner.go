// Package ui renders a single-line spinner that displays a step label and the
// most recent line of streamed subprocess output. It degrades to plain status
// lines when stdout is not a TTY so output stays pipe-friendly.
package ui

import (
	"bytes"
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
	buf     bytes.Buffer
	stopped bool
	wg      sync.WaitGroup
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
		started: time.Now(),
	}
	if tty {
		s.wg.Add(1)
		go s.loop()
	} else {
		fmt.Fprintf(out, "    %s\n", label)
	}
	return s
}

func (s *Step) loop() {
	defer s.wg.Done()
	t := time.NewTicker(frameInterval)
	defer t.Stop()
	for range t.C {
		s.mu.Lock()
		if s.stopped {
			s.mu.Unlock()
			return
		}
		frame := frames[s.frame%len(frames)]
		s.frame++
		tail := s.tail
		s.mu.Unlock()
		s.paint(frame, tail)
	}
}

// paint writes one spinner frame. Called without s.mu held so a slow terminal
// can't backpressure subprocess Writes.
func (s *Step) paint(frame rune, tail string) {
	suffix := ""
	if tail != "" {
		suffix = " — " + truncate(tail, tailMaxRunes)
	}
	fmt.Fprintf(s.out, "%s    %c %s%s", clearLine, frame, s.label, suffix)
}

// Write satisfies io.Writer. The most recent non-empty line updates the
// spinner tail; the full bytes are appended to the replay buffer.
func (s *Step) Write(p []byte) (int, error) {
	s.mu.Lock()
	s.buf.Write(p)
	if last := lastLine(p); last != "" {
		s.tail = last
	}
	s.mu.Unlock()
	return len(p), nil
}

// Done finalises the step. icon is the leading status glyph (✓, ✗, ·).
// status is the brief result text. dumpBuffer prints the captured output below
// the final line; use it for failures or when verbose mode is on.
func (s *Step) Done(icon, status string, dumpBuffer bool) {
	if s.tty {
		s.mu.Lock()
		s.stopped = true
		s.mu.Unlock()
		s.wg.Wait()
		fmt.Fprint(s.out, clearLine)
	}
	elapsed := time.Since(s.started).Round(100 * time.Millisecond)
	fmt.Fprintf(s.out, "    %s %s — %s (%s)\n", icon, s.label, status, elapsed)
	if dumpBuffer {
		s.replay()
	}
}

func (s *Step) replay() {
	s.mu.Lock()
	defer s.mu.Unlock()
	body := bytes.TrimRight(s.buf.Bytes(), "\n")
	if len(body) == 0 {
		return
	}
	for _, line := range bytes.Split(body, []byte{'\n'}) {
		fmt.Fprintf(s.out, "      %s\n", line)
	}
}

// lastLine returns the last non-blank line in p, trimmed.
func lastLine(p []byte) string {
	end := len(p)
	for end > 0 {
		// strip trailing newlines
		for end > 0 && p[end-1] == '\n' {
			end--
		}
		if end == 0 {
			return ""
		}
		start := bytes.LastIndexByte(p[:end], '\n') + 1
		line := strings.TrimSpace(string(p[start:end]))
		if line != "" {
			return line
		}
		end = start - 1
		if end < 0 {
			return ""
		}
	}
	return ""
}

func truncate(s string, max int) string {
	if len(s) <= max {
		return s
	}
	r := []rune(s)
	if len(r) <= max {
		return s
	}
	return string(r[:max-1]) + "…"
}
