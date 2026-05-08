package doctor

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/hubermjonathan/dotfiles/internal/linker"
	"github.com/hubermjonathan/dotfiles/internal/module"
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

func ExpandHome(path string) string {
	if strings.HasPrefix(path, "~/") {
		home, _ := os.UserHomeDir()
		return home + path[1:]
	}
	return path
}

func Check(mod *module.Module) []Issue {
	var issues []Issue

	// Check symlinks
	for source, target := range mod.Links {
		sourcePath := fmt.Sprintf("%s/%s", mod.Path, source)
		targetPath := ExpandHome(target)
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
		check := ParseCheck(strings.Replace(h, "~", ExpandHome("~"), 1))
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
