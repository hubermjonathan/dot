package linker

import (
	"os"
	"path/filepath"
	"testing"
)

func TestFindOrphansBasic(t *testing.T) {
	repo := t.TempDir()
	home := t.TempDir()

	srcDir := filepath.Join(repo, "modules", "macos")
	if err := os.MkdirAll(srcDir, 0755); err != nil {
		t.Fatal(err)
	}
	src := filepath.Join(srcDir, "wallpaper.jpg")
	if err := os.WriteFile(src, []byte("x"), 0644); err != nil {
		t.Fatal(err)
	}

	currentDir := filepath.Join(home, "Pictures")
	oldDir := filepath.Join(home, "Documents", "Images")
	if err := os.MkdirAll(currentDir, 0755); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(oldDir, 0755); err != nil {
		t.Fatal(err)
	}

	currentTgt := filepath.Join(currentDir, "wallpaper.jpg")
	oldTgt := filepath.Join(oldDir, "wallpaper.jpg")
	if err := os.Symlink(src, currentTgt); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(src, oldTgt); err != nil {
		t.Fatal(err)
	}

	declared := map[string]bool{currentTgt: true}
	orphans, err := FindOrphans([]string{home}, repo, declared)
	if err != nil {
		t.Fatal(err)
	}
	if len(orphans) != 1 {
		t.Fatalf("want 1 orphan, got %d: %+v", len(orphans), orphans)
	}
	if orphans[0].Path != oldTgt {
		t.Errorf("want %s, got %s", oldTgt, orphans[0].Path)
	}
}

func TestFindOrphansIgnoresNonRepoSymlinks(t *testing.T) {
	repo := t.TempDir()
	home := t.TempDir()

	other := filepath.Join(home, "external.txt")
	if err := os.WriteFile(other, []byte("y"), 0644); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(other, filepath.Join(home, "link.txt")); err != nil {
		t.Fatal(err)
	}

	orphans, err := FindOrphans([]string{home}, repo, nil)
	if err != nil {
		t.Fatal(err)
	}
	if len(orphans) != 0 {
		t.Errorf("want 0, got %+v", orphans)
	}
}

func TestFindOrphansSkipsWorktrees(t *testing.T) {
	repo := t.TempDir()
	home := t.TempDir()

	srcDir := filepath.Join(repo, "modules", "macos")
	if err := os.MkdirAll(srcDir, 0755); err != nil {
		t.Fatal(err)
	}
	src := filepath.Join(srcDir, "f.txt")
	if err := os.WriteFile(src, []byte("x"), 0644); err != nil {
		t.Fatal(err)
	}

	worktreeDir := filepath.Join(repo, ".claude", "worktrees", "wt1")
	if err := os.MkdirAll(worktreeDir, 0755); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(src, filepath.Join(worktreeDir, "linked.txt")); err != nil {
		t.Fatal(err)
	}

	orphans, err := FindOrphans([]string{repo}, repo, nil)
	if err != nil {
		t.Fatal(err)
	}
	if len(orphans) != 0 {
		t.Errorf("want 0 (worktrees skipped), got %+v", orphans)
	}
	_ = home
}

func TestFindOrphansIncludesDanglingWorktreeLinks(t *testing.T) {
	repo := t.TempDir()
	home := t.TempDir()

	dangling := filepath.Join(repo, ".claude", "worktrees", "deleted", "modules", "macos", "wallpaper.jpg")
	tgt := filepath.Join(home, "Documents", "Images", "wallpaper.jpg")
	if err := os.MkdirAll(filepath.Dir(tgt), 0755); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(dangling, tgt); err != nil {
		t.Fatal(err)
	}

	orphans, err := FindOrphans([]string{home}, repo, nil)
	if err != nil {
		t.Fatal(err)
	}
	if len(orphans) != 1 || orphans[0].Path != tgt {
		t.Errorf("want dangling-worktree link reported, got %+v", orphans)
	}
}

func TestRemoveOrphanCleansEmptyParent(t *testing.T) {
	home := t.TempDir()
	parent := filepath.Join(home, "subdir")
	if err := os.MkdirAll(parent, 0755); err != nil {
		t.Fatal(err)
	}
	link := filepath.Join(parent, "link")
	if err := os.Symlink("/nonexistent", link); err != nil {
		t.Fatal(err)
	}

	if err := RemoveOrphan(Orphan{Path: link}); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(link); !os.IsNotExist(err) {
		t.Errorf("link should be gone")
	}
	if _, err := os.Stat(parent); !os.IsNotExist(err) {
		t.Errorf("empty parent should be gone")
	}
}
