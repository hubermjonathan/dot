package module_test

import (
	"os"
	"path/filepath"
	"reflect"
	"testing"

	"github.com/hubermjonathan/dotfiles/internal/module"
)

func TestEnsureAndLoadSkips(t *testing.T) {
	path := filepath.Join(t.TempDir(), ".dot-skips")

	if entries, err := module.LoadSkips(path); err != nil || entries != nil {
		t.Fatalf("missing file: entries=%v err=%v, want none", entries, err)
	}
	if created, err := module.EnsureSkips(path); err != nil || !created {
		t.Fatalf("first EnsureSkips: created=%v err=%v", created, err)
	}

	// The header is only comments, and an existing file is never overwritten.
	if entries, _ := module.LoadSkips(path); entries != nil {
		t.Fatalf("header parsed as entries: %v", entries)
	}
	f, _ := os.OpenFile(path, os.O_APPEND|os.O_WRONLY, 0)
	f.WriteString("\nmacos/sudo-touchid  # no Touch ID here\n  apps\n")
	f.Close()
	if created, err := module.EnsureSkips(path); err != nil || created {
		t.Fatalf("second EnsureSkips: created=%v err=%v", created, err)
	}

	entries, err := module.LoadSkips(path)
	if err != nil {
		t.Fatal(err)
	}
	if want := []string{"macos/sudo-touchid", "apps"}; !reflect.DeepEqual(entries, want) {
		t.Fatalf("entries = %v, want %v", entries, want)
	}
}

func TestApplySkips(t *testing.T) {
	step := func(name string) module.Step { return module.Step{Name: name, Run: "true"} }
	mods := []*module.Module{
		{Name: "apps", Provision: []module.Step{step("pull")}},
		{Name: "macos", PostLink: []module.Step{step("sudo-touchid"), step("dark-mode")}},
	}

	kept, applied, unknown := module.ApplySkips(mods, []string{"apps", "apps/pull", "macos/sudo-touchid", "macos/typo"})

	if len(kept) != 1 || kept[0].Name != "macos" {
		t.Fatalf("kept = %v, want only macos", kept)
	}
	if got := kept[0].PostLink; len(got) != 1 || got[0].Name != "dark-mode" {
		t.Fatalf("macos post_link = %v, want only dark-mode", got)
	}
	if len(mods[1].PostLink) != 2 {
		t.Fatal("ApplySkips changed the input module")
	}
	if want := []string{"apps", "macos/sudo-touchid"}; !reflect.DeepEqual(applied, want) {
		t.Fatalf("applied = %v, want %v", applied, want)
	}
	if want := []string{"macos/typo"}; !reflect.DeepEqual(unknown, want) {
		t.Fatalf("unknown = %v, want %v", unknown, want)
	}
}
