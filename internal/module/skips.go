package module

import (
	"bufio"
	"bytes"
	"errors"
	"io/fs"
	"os"
	"strings"
)

// SkipsPath is the machine-local file that lists what dot skips on this
// machine. Dot creates it on install and link. It isn't tracked in the repo.
const SkipsPath = "~/.dot-skips"

const skipsHeader = `# What dot skips on this machine. One entry per line:
#   <module>         skip the whole module
#   <module>/<step>  skip one step and its health check
`

// EnsureSkips creates the skips file with a header if it doesn't exist yet,
// and leaves an existing file alone.
func EnsureSkips(path string) (created bool, err error) {
	f, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0o644)
	if errors.Is(err, fs.ErrExist) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	defer f.Close()
	if _, err := f.WriteString(skipsHeader); err != nil {
		return false, err
	}
	return true, nil
}

// LoadSkips reads the skips file. A missing file skips nothing.
func LoadSkips(path string) ([]string, error) {
	data, err := os.ReadFile(path)
	if errors.Is(err, fs.ErrNotExist) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	var entries []string
	sc := bufio.NewScanner(bytes.NewReader(data))
	for sc.Scan() {
		line, _, _ := strings.Cut(sc.Text(), "#")
		if line = strings.TrimSpace(line); line != "" {
			entries = append(entries, line)
		}
	}
	return entries, sc.Err()
}

// ApplySkips drops skipped modules and steps. It returns the modules that are
// left, the entries it applied, and the entries that match nothing.
func ApplySkips(mods []*Module, entries []string) (kept []*Module, applied, unknown []string) {
	want := map[string]bool{}
	for _, e := range entries {
		want[e] = true
	}
	used := map[string]bool{}
	skip := func(id string) bool {
		if want[id] {
			used[id] = true
			applied = append(applied, id)
		}
		return want[id]
	}
	keepSteps := func(mod string, steps []Step) []Step {
		var out []Step
		for _, s := range steps {
			if !skip(mod + "/" + s.Name) {
				out = append(out, s)
			}
		}
		return out
	}

	for _, mod := range mods {
		if skip(mod.Name) {
			for _, steps := range [][]Step{mod.Health, mod.PostLink, mod.Provision} {
				for _, s := range steps {
					used[mod.Name+"/"+s.Name] = true
				}
			}
			continue
		}
		m := *mod
		m.Health = keepSteps(m.Name, m.Health)
		m.PostLink = keepSteps(m.Name, m.PostLink)
		m.Provision = keepSteps(m.Name, m.Provision)
		kept = append(kept, &m)
	}
	for _, e := range entries {
		if !used[e] {
			unknown = append(unknown, e)
		}
	}
	return kept, applied, unknown
}
