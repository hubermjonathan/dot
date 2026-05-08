package module_test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/hubermjonathan/dotfiles/internal/module"
)

func TestDiscover(t *testing.T) {
	tmp := t.TempDir()

	// Create a valid module
	modDir := filepath.Join(tmp, "git")
	os.MkdirAll(modDir, 0755)
	os.WriteFile(filepath.Join(modDir, "module.toml"), []byte(`
[module]
name = "git"
description = "Git config"

[links]
".gitconfig" = "~/.gitconfig"
`), 0644)

	// Create a dir without module.toml (should be skipped)
	os.MkdirAll(filepath.Join(tmp, "random"), 0755)

	modules, err := module.Discover(tmp)
	if err != nil {
		t.Fatal(err)
	}
	if len(modules) != 1 {
		t.Fatalf("expected 1 module, got %d", len(modules))
	}
	if modules[0].Name != "git" {
		t.Fatalf("expected name 'git', got '%s'", modules[0].Name)
	}
}
