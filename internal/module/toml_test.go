package module_test

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/hubermjonathan/dotfiles/internal/module"
)

func loadTOML(t *testing.T, body string) (*module.Module, error) {
	t.Helper()
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "module.toml"), []byte(body), 0o644); err != nil {
		t.Fatal(err)
	}
	return module.Load(dir)
}

func TestLoadNamedSteps(t *testing.T) {
	mod, err := loadTOML(t, `
[module]
name = "demo"

[health]
checks = [{ name = "app-installed", check = "dir_exists:/Applications" }]

[setup]
post_link = [{ name = "make-dir", run = "mkdir -p ~/x", check = "dir_exists:~/x" }]
provision = [{ name = "login", run = "true" }]
`)
	if err != nil {
		t.Fatal(err)
	}
	if mod.PostLink[0].Name != "make-dir" || mod.PostLink[0].Run != "mkdir -p ~/x" {
		t.Fatalf("post_link = %+v", mod.PostLink)
	}
	var names []string
	for _, c := range mod.Checks() {
		names = append(names, c.Name)
	}
	if got := strings.Join(names, ","); got != "app-installed,make-dir" {
		t.Fatalf("checks = %s, want app-installed,make-dir", got)
	}
}

func TestLoadRejectsBadSteps(t *testing.T) {
	cases := map[string]string{
		"unnamed string":   `post_link = ["true"]`,
		"missing name":     `post_link = [{ run = "true" }]`,
		"not kebab-case":   `post_link = [{ name = "Make_Dir", run = "true" }]`,
		"missing run":      `post_link = [{ name = "a" }]`,
		"duplicate name":   `post_link = [{ name = "a", run = "true" }]` + "\n" + `provision = [{ name = "a", run = "true" }]`,
		"check with a run": "[health]\n" + `checks = [{ name = "a", check = "dir_exists:/", run = "true" }]`,
	}
	for name, body := range cases {
		t.Run(name, func(t *testing.T) {
			if !strings.HasPrefix(body, "[health]") {
				body = "[setup]\n" + body
			}
			if _, err := loadTOML(t, "[module]\nname = \"demo\"\n"+body); err == nil {
				t.Fatal("expected an error")
			}
		})
	}
}

// Every module in the repo must load, so a step without a name fails `go test`
// instead of making dot skip the module with a warning.
func TestRepoModulesLoad(t *testing.T) {
	dirs, err := filepath.Glob("../../modules/*/module.toml")
	if err != nil || len(dirs) == 0 {
		t.Fatalf("no modules found: %v", err)
	}
	for _, f := range dirs {
		if _, err := module.Load(filepath.Dir(f)); err != nil {
			t.Errorf("%s: %v", f, err)
		}
	}
}
