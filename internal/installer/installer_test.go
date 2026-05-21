package installer_test

import (
	"testing"

	"github.com/hubermjonathan/dotfiles/internal/installer"
)

func TestBuildBrewArgs(t *testing.T) {
	args := installer.BuildBrewArgs([]string{"git", "zsh"})
	expected := []string{"install", "git", "zsh"}
	if len(args) != len(expected) {
		t.Fatalf("expected %v, got %v", expected, args)
	}
	for i, a := range args {
		if a != expected[i] {
			t.Fatalf("arg[%d]: expected %q, got %q", i, expected[i], a)
		}
	}
}

func TestBuildCaskArgs(t *testing.T) {
	args := installer.BuildCaskArgs([]string{"ghostty"})
	expected := []string{"install", "--cask", "ghostty"}
	if len(args) != len(expected) {
		t.Fatalf("expected %v, got %v", expected, args)
	}
	for i, a := range args {
		if a != expected[i] {
			t.Fatalf("arg[%d]: expected %q, got %q", i, expected[i], a)
		}
	}
}
