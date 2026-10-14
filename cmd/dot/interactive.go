package main

import (
	"fmt"
	"os"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/hubermjonathan/dotfiles/internal/tui"
)

func runInteractive() error {
	modules, err := getModules(nil)
	if err != nil {
		return err
	}

	items := make([]tui.Item, len(modules))
	for i, mod := range modules {
		state, _ := moduleState(mod)
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
