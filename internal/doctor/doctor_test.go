package doctor_test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/hubermjonathan/dotfiles/internal/doctor"
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
