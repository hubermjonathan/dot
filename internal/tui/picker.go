package tui

import (
	"fmt"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type Item struct {
	Name        string
	Description string
	State       string
	Selected    bool
}

type Model struct {
	Items    []Item
	cursor   int
	Chosen   bool
	Quitting bool
}

func NewModel(items []Item) Model {
	return Model{Items: items}
}

func (m Model) Init() tea.Cmd {
	return nil
}

func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "q", "ctrl+c":
			m.Quitting = true
			return m, tea.Quit
		case "up", "k":
			if m.cursor > 0 {
				m.cursor--
			}
		case "down", "j":
			if m.cursor < len(m.Items)-1 {
				m.cursor++
			}
		case " ":
			if m.cursor >= 0 && m.cursor < len(m.Items) {
				m.Items[m.cursor].Selected = !m.Items[m.cursor].Selected
			}
		case "enter":
			m.Chosen = true
			return m, tea.Quit
		}
	}
	return m, nil
}

func (m Model) View() string {
	s := "Select modules to set up (space=toggle, enter=confirm, q=quit):\n\n"

	selectedStyle := lipgloss.NewStyle().Foreground(lipgloss.Color("40"))
	stateStyle := lipgloss.NewStyle().Foreground(lipgloss.Color("240"))

	for i, item := range m.Items {
		cursor := "  "
		if m.cursor == i {
			cursor = "> "
		}
		check := "[ ]"
		if item.Selected {
			check = selectedStyle.Render("[x]")
		}
		state := stateStyle.Render(fmt.Sprintf("[%s]", item.State))
		s += fmt.Sprintf("%s%s %s %-12s %s\n", cursor, check, state, item.Name, item.Description)
	}

	return s
}

func (m Model) SelectedItems() []string {
	var names []string
	for _, item := range m.Items {
		if item.Selected {
			names = append(names, item.Name)
		}
	}
	return names
}
