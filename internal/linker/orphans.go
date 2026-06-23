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

var skipDirs = map[string]bool{
	"Caches":       true,
	".Trash":       true,
	"node_modules": true,
	".git":         true,
}

func FindOrphans(roots []string, repoRoot string, declared map[string]bool) ([]Orphan, error) {
	repoModulesPrefix := filepath.Join(repoRoot, "modules") + string(filepath.Separator)
	worktreesPrefix := filepath.Join(repoRoot, ".claude", "worktrees") + string(filepath.Separator)

	var orphans []Orphan
	seen := map[string]bool{}

	for _, root := range roots {
		err := filepath.WalkDir(root, func(p string, d fs.DirEntry, err error) error {
			if err != nil {
				if os.IsPermission(err) || os.IsNotExist(err) {
					return nil
				}
				return nil
			}
			if d.IsDir() {
				if skipDirs[d.Name()] {
					return fs.SkipDir
				}
				if strings.HasPrefix(p+string(filepath.Separator), worktreesPrefix) {
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
			if !strings.HasPrefix(lname, repoModulesPrefix) && !strings.Contains(lname, "/.claude/worktrees/") {
				return nil
			}
			if declared[p] {
				return nil
			}
			if seen[p] {
				return nil
			}
			seen[p] = true
			orphans = append(orphans, Orphan{Path: p, Target: lname})
			return nil
		})
		if err != nil {
			return orphans, err
		}
	}
	return orphans, nil
}

func RemoveOrphan(o Orphan) error {
	if err := os.Remove(o.Path); err != nil {
		return err
	}
	parent := filepath.Dir(o.Path)
	_ = os.Remove(parent)
	return nil
}
