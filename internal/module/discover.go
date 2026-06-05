package module

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
)

func Discover(modulesDir string) ([]*Module, error) {
	entries, err := os.ReadDir(modulesDir)
	if err != nil {
		return nil, err
	}

	var modules []*Module
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		dir := filepath.Join(modulesDir, entry.Name())
		tomlPath := filepath.Join(dir, "module.toml")
		if _, err := os.Stat(tomlPath); os.IsNotExist(err) {
			continue
		}
		mod, err := Load(dir)
		if err != nil {
			fmt.Fprintf(os.Stderr, "warning: skipping module %s: %v\n", entry.Name(), err)
			continue
		}
		modules = append(modules, mod)
	}

	sort.Slice(modules, func(i, j int) bool {
		return modules[i].Name < modules[j].Name
	})

	return modules, nil
}
