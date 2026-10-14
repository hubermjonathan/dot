package linker

import (
	"io/fs"
	"os"
	"path/filepath"
	"strings"
)

type Orphan struct {
	Path   string
	Target string
}

// worktreeDirs are where agents put a repo's worktrees, relative to the repo root.
var worktreeDirs = []string{".claude/worktrees", ".scratch/worktrees"}

var skipDirs = map[string]bool{
	"Caches":       true,
	".Trash":       true,
	"node_modules": true,
	".git":         true,
}

func FindOrphans(root, repoRoot string, declared map[string]bool) ([]Orphan, error) {
	repoModulesPrefix := filepath.Join(repoRoot, "modules") + string(filepath.Separator)
	inWorktree := func(p string) bool {
		for _, dir := range worktreeDirs {
			if strings.HasPrefix(p, filepath.Join(repoRoot, dir)+string(filepath.Separator)) {
				return true
			}
		}
		return false
	}

	var orphans []Orphan
	err := filepath.WalkDir(root, func(p string, d fs.DirEntry, err error) error {
		if err != nil {
			return nil
		}
		if d.IsDir() {
			if skipDirs[d.Name()] {
				return fs.SkipDir
			}
			if inWorktree(p + string(filepath.Separator)) {
				return fs.SkipDir
			}
			return nil
		}
		if d.Type()&fs.ModeSymlink == 0 {
			return nil
		}
		lname, lerr := os.Readlink(p)
		if lerr != nil {
			return nil
		}
		if !strings.Contains(lname, "/modules/") {
			return nil
		}
		if !strings.HasPrefix(lname, repoModulesPrefix) && !inWorktree(lname) {
			return nil
		}
		if declared[p] {
			return nil
		}
		orphans = append(orphans, Orphan{Path: p, Target: lname})
		return nil
	})
	return orphans, err
}

func RemoveOrphan(o Orphan) error {
	if err := os.Remove(o.Path); err != nil {
		return err
	}
	parent := filepath.Dir(o.Path)
	_ = os.Remove(parent)
	return nil
}
