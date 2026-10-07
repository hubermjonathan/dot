package module

type Module struct {
	Name        string
	Description string
	Path        string
	Links       map[string]string
	Deps        Deps
	Apps        Apps
	Health      []Step
	PostLink    []Step
	Provision   []Step
	Interactive bool
}

type Deps struct {
	Brew []string
}

type Apps struct {
	Cask []string
}

// Step is one named setup command or health check. Names are unique within a
// module, so ~/.dot-skips can name any step as <module>/<name>.
type Step struct {
	Name  string `toml:"name"`
	Run   string `toml:"run"`   // sh -c command; empty for a [health] check
	Check string `toml:"check"` // optional for setup steps; see doctor.ParseCheck
}

// Checks returns every health check in the module: the [health] checks plus
// the checks attached to setup steps.
func (m *Module) Checks() []Step {
	var out []Step
	for _, steps := range [][]Step{m.Health, m.PostLink, m.Provision} {
		for _, s := range steps {
			if s.Check != "" {
				out = append(out, s)
			}
		}
	}
	return out
}
