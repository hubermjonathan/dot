package doctor

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"

	"github.com/hubermjonathan/dotfiles/internal/linker"
	"github.com/hubermjonathan/dotfiles/internal/module"
	"github.com/hubermjonathan/dotfiles/internal/pathutil"
)

type Issue struct {
	Module      string
	Type        string
	Description string
	FixAction   func() error
}

func ParseCheck(check string) func() error {
	parts := strings.SplitN(check, ":", 2)
	if len(parts) != 2 {
		return nil
	}

	kind, arg := parts[0], parts[1]
	switch kind {
	case "file_exists":
		return func() error {
			if _, err := os.Stat(arg); err != nil {
				return fmt.Errorf("file not found: %s", arg)
			}
			return nil
		}
	case "dir_exists":
		return func() error {
			info, err := os.Stat(arg)
			if err != nil {
				return fmt.Errorf("dir not found: %s", arg)
			}
			if !info.IsDir() {
				return fmt.Errorf("not a directory: %s", arg)
			}
			return nil
		}
	case "command_succeeds":
		return func() error {
			cmd := exec.Command("sh", "-c", arg)
			if err := cmd.Run(); err != nil {
				return fmt.Errorf("command failed: %s", arg)
			}
			return nil
		}
	}
	return nil
}

func Check(mod *module.Module) []Issue {
	var issues []Issue

	// Check symlinks
	keys := make([]string, 0, len(mod.Links))
	for k := range mod.Links {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	for _, source := range keys {
		target := mod.Links[source]
		sourcePath := filepath.Join(mod.Path, source)
		targetPath := pathutil.ExpandHome(target)
		status := linker.Verify(sourcePath, targetPath)
		if status != linker.StatusOK {
			src := sourcePath
			tgt := targetPath
			issues = append(issues, Issue{
				Module:      mod.Name,
				Type:        "symlink",
				Description: fmt.Sprintf("%s → %s (%s)", source, target, statusName(status)),
				FixAction: func() error {
					_, err := linker.Link(src, tgt, "")
					return err
				},
			})
		}
	}

	// Check health
	for _, h := range mod.Health {
		check := ParseCheck(strings.Replace(h, "~", pathutil.ExpandHome("~"), 1))
		if check == nil {
			continue
		}
		if err := check(); err != nil {
			issues = append(issues, Issue{
				Module:      mod.Name,
				Type:        "health",
				Description: err.Error(),
				FixAction:   nil,
			})
		}
	}

	return issues
}

func statusName(s linker.Status) string {
	switch s {
	case linker.StatusMissing:
		return "missing"
	case linker.StatusBroken:
		return "broken"
	case linker.StatusWrongTarget:
		return "wrong target"
	case linker.StatusNotSymlink:
		return "not a symlink"
	default:
		return "unknown"
	}
}
