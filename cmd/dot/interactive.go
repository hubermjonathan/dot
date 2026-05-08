package main

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/hubermjonathan/dotfiles/internal/linker"
	"github.com/hubermjonathan/dotfiles/internal/module"
	"github.com/hubermjonathan/dotfiles/internal/tui"
)

func runInteractive() error {
	modulesDir := filepath.Join(getRepoRoot(), "modules")
	modules, err := module.Discover(modulesDir)
	if err != nil {
		return err
	}

	items := make([]tui.Item, len(modules))
	for i, mod := range modules {
		state := getModuleState(mod)
		items[i] = tui.Item{
			Name:        mod.Name,
			Description: mod.Description,
			State:       state,
		}
	}

	m := tui.NewModel(items)
	p := tea.NewProgram(m)
	result, err := p.Run()
	if err != nil {
		return err
	}

	final := result.(tui.Model)
	if final.Quitting || !final.Chosen {
		return nil
	}

	selected := final.SelectedItems()
	if len(selected) == 0 {
		fmt.Println("nothing selected")
		return nil
	}

	fmt.Println()
	if err := runInstall(nil, selected); err != nil {
		fmt.Fprintf(os.Stderr, "install errors (continuing): %v\n", err)
	}
	return runLink(nil, selected)
}

func getModuleState(mod *module.Module) string {
	if len(mod.Links) == 0 {
		return "no-links"
	}
	linked, broken := 0, 0
	keys := make([]string, 0, len(mod.Links))
	for k := range mod.Links {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	for _, source := range keys {
		target := mod.Links[source]
		sourcePath := filepath.Join(mod.Path, source)
		targetPath := expandHome(target)
		status := linker.Verify(sourcePath, targetPath)
		switch status {
		case linker.StatusOK:
			linked++
		case linker.StatusBroken, linker.StatusWrongTarget:
			broken++
		}
	}
	total := len(mod.Links)
	if linked == total {
		return "linked"
	}
	if broken > 0 {
		return "broken"
	}
	if linked > 0 {
		return "partial"
	}
	return "unlinked"
}
