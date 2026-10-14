package doctor_test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/hubermjonathan/dotfiles/internal/doctor"
	"github.com/hubermjonathan/dotfiles/internal/module"
)

func TestParseCheck_FileExists(t *testing.T) {
	tmp := t.TempDir()
	f := filepath.Join(tmp, "exists.txt")
	os.WriteFile(f, []byte("x"), 0644)

	check := doctor.ParseCheck("file_exists:" + f)
	if check == nil {
		t.Fatal("expected non-nil check")
	}
	if err := check(); err != nil {
		t.Fatalf("expected nil error, got %v", err)
	}
}

func TestParseCheck_FileNotExists(t *testing.T) {
	check := doctor.ParseCheck("file_exists:/nonexistent/path")
	if check == nil {
		t.Fatal("expected non-nil check")
	}
	if err := check(); err == nil {
		t.Fatal("expected error for missing file")
	}
}

func TestParseCheck_DirExists(t *testing.T) {
	tmp := t.TempDir()
	check := doctor.ParseCheck("dir_exists:" + tmp)
	if err := check(); err != nil {
		t.Fatalf("expected nil, got %v", err)
	}
}

func TestParseCheck_CommandSucceeds(t *testing.T) {
	check := doctor.ParseCheck("command_succeeds:echo hello")
	if err := check(); err != nil {
		t.Fatalf("expected nil, got %v", err)
	}
}

func TestFixBacksUpFile(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	modDir := t.TempDir()
	os.WriteFile(filepath.Join(modDir, ".rc"), []byte("repo"), 0644)
	os.WriteFile(filepath.Join(home, ".rc"), []byte("mine"), 0644)
	mod := &module.Module{Name: "demo", Path: modDir, Links: map[string]string{".rc": "~/.rc"}}

	issues := doctor.Check(mod)
	if len(issues) != 1 || issues[0].FixAction == nil {
		t.Fatalf("want one fixable issue, got %+v", issues)
	}
	if err := issues[0].FixAction(); err != nil {
		t.Fatal(err)
	}

	backups, _ := filepath.Glob(filepath.Join(home, ".dotfiles-backup", "demo", ".rc.*"))
	if len(backups) != 1 {
		t.Fatalf("want one backup, got %v", backups)
	}
	if data, _ := os.ReadFile(backups[0]); string(data) != "mine" {
		t.Fatalf("backup holds %q, want %q", data, "mine")
	}
}
