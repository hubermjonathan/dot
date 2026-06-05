package linker_test

import (
	"crypto/sha256"
	"encoding/hex"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/hubermjonathan/dotfiles/internal/linker"
)

func TestLink_CreatesSymlink(t *testing.T) {
	tmp := t.TempDir()
	source := filepath.Join(tmp, "source.txt")
	target := filepath.Join(tmp, "target.txt")
	os.WriteFile(source, []byte("content"), 0644)

	result, err := linker.Link(source, target, "")
	if err != nil {
		t.Fatal(err)
	}
	if result != linker.Created {
		t.Fatalf("expected Created, got %v", result)
	}

	resolved, _ := os.Readlink(target)
	if resolved != source {
		t.Fatalf("symlink points to %s, expected %s", resolved, source)
	}
}

func TestLink_SkipsCorrectSymlink(t *testing.T) {
	tmp := t.TempDir()
	source := filepath.Join(tmp, "source.txt")
	target := filepath.Join(tmp, "target.txt")
	os.WriteFile(source, []byte("content"), 0644)
	os.Symlink(source, target)

	result, err := linker.Link(source, target, "")
	if err != nil {
		t.Fatal(err)
	}
	if result != linker.Skipped {
		t.Fatalf("expected Skipped, got %v", result)
	}
}

func TestLink_ReplacesWrongSymlink(t *testing.T) {
	tmp := t.TempDir()
	source := filepath.Join(tmp, "source.txt")
	wrong := filepath.Join(tmp, "wrong.txt")
	target := filepath.Join(tmp, "target.txt")
	os.WriteFile(source, []byte("right"), 0644)
	os.WriteFile(wrong, []byte("wrong"), 0644)
	os.Symlink(wrong, target)

	result, err := linker.Link(source, target, "")
	if err != nil {
		t.Fatal(err)
	}
	if result != linker.Replaced {
		t.Fatalf("expected Replaced, got %v", result)
	}
	resolved, _ := os.Readlink(target)
	if resolved != source {
		t.Fatalf("symlink points to %s, expected %s", resolved, source)
	}
}

func TestLink_BacksUpExistingFile(t *testing.T) {
	tmp := t.TempDir()
	source := filepath.Join(tmp, "source.txt")
	target := filepath.Join(tmp, "target.txt")
	backupDir := filepath.Join(tmp, "backup")
	os.WriteFile(source, []byte("new"), 0644)
	os.WriteFile(target, []byte("old"), 0644)

	result, err := linker.Link(source, target, backupDir)
	if err != nil {
		t.Fatal(err)
	}
	if result != linker.Replaced {
		t.Fatalf("expected Replaced, got %v", result)
	}

	sum := sha256.Sum256([]byte(target))
	hash := hex.EncodeToString(sum[:])[:6]
	prefix := "target.txt."
	entries, err := os.ReadDir(backupDir)
	if err != nil {
		t.Fatal(err)
	}
	var found string
	for _, e := range entries {
		n := e.Name()
		if strings.HasPrefix(n, prefix) && strings.HasSuffix(n, "."+hash) {
			found = n
			break
		}
	}
	if found == "" {
		t.Fatalf("backup file matching %s*.%s not found in %v", prefix, hash, entries)
	}
	data, err := os.ReadFile(filepath.Join(backupDir, found))
	if err != nil {
		t.Fatal(err)
	}
	if string(data) != "old" {
		t.Fatalf("backup content = %q, expected 'old'", data)
	}
}

func TestLink_BacksUpDoesNotOverwrite(t *testing.T) {
	tmp := t.TempDir()
	source := filepath.Join(tmp, "source.txt")
	target := filepath.Join(tmp, "target.txt")
	backupDir := filepath.Join(tmp, "backup")
	os.WriteFile(source, []byte("new"), 0644)

	for i, content := range []string{"old1", "old2"} {
		os.WriteFile(target, []byte(content), 0644)
		if _, err := linker.Link(source, target, backupDir); err != nil {
			t.Fatalf("link iter %d: %v", i, err)
		}
		os.Remove(target)
	}

	entries, err := os.ReadDir(backupDir)
	if err != nil {
		t.Fatal(err)
	}
	if len(entries) < 2 {
		t.Fatalf("expected ≥2 backup files, got %d: %v", len(entries), entries)
	}
}

func TestUnlink_RemovesSymlink(t *testing.T) {
	tmp := t.TempDir()
	source := filepath.Join(tmp, "source.txt")
	target := filepath.Join(tmp, "target.txt")
	os.WriteFile(source, []byte("content"), 0644)
	os.Symlink(source, target)

	err := linker.Unlink(target)
	if err != nil {
		t.Fatal(err)
	}

	_, err = os.Lstat(target)
	if !os.IsNotExist(err) {
		t.Fatal("expected target to be removed")
	}
}

func TestVerify(t *testing.T) {
	tmp := t.TempDir()
	source := filepath.Join(tmp, "source.txt")
	target := filepath.Join(tmp, "target.txt")
	os.WriteFile(source, []byte("content"), 0644)
	os.Symlink(source, target)

	status := linker.Verify(source, target)
	if status != linker.StatusOK {
		t.Fatalf("expected StatusOK, got %v", status)
	}
}
