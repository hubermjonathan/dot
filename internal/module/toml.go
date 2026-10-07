package module

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"

	"github.com/BurntSushi/toml"
)

type tomlConfig struct {
	Module tomlModule        `toml:"module"`
	Links  map[string]string `toml:"links"`
	Deps   tomlDeps          `toml:"deps"`
	Apps   tomlApps          `toml:"apps"`
	Health tomlHealth        `toml:"health"`
	Setup  tomlSetup         `toml:"setup"`
}

type tomlModule struct {
	Name        string `toml:"name"`
	Description string `toml:"description"`
}

type tomlDeps struct {
	Brew []string `toml:"brew"`
}

type tomlApps struct {
	Cask []string `toml:"cask"`
}

type tomlHealth struct {
	Checks []Step `toml:"checks"`
}

type tomlSetup struct {
	PostLink    []Step `toml:"post_link"`
	Provision   []Step `toml:"provision"`
	Interactive bool   `toml:"interactive"`
}

func Load(dir string) (*Module, error) {
	configPath := filepath.Join(dir, "module.toml")
	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, err
	}

	var cfg tomlConfig
	if err := toml.Unmarshal(data, &cfg); err != nil {
		return nil, err
	}
	if err := validateSteps(cfg); err != nil {
		return nil, err
	}

	return &Module{
		Name:        cfg.Module.Name,
		Description: cfg.Module.Description,
		Path:        dir,
		Links:       cfg.Links,
		Deps:        Deps{Brew: cfg.Deps.Brew},
		Apps:        Apps{Cask: cfg.Apps.Cask},
		Health:      cfg.Health.Checks,
		PostLink:    cfg.Setup.PostLink,
		Provision:   cfg.Setup.Provision,
		Interactive: cfg.Setup.Interactive,
	}, nil
}

var stepName = regexp.MustCompile(`^[a-z0-9]+(-[a-z0-9]+)*$`)

// validateSteps requires every step to have a unique kebab-case name, setup
// steps to have a command, and health checks to have a check and no command.
func validateSteps(cfg tomlConfig) error {
	lists := []struct {
		kind  string
		steps []Step
	}{
		{"health check", cfg.Health.Checks},
		{"post_link step", cfg.Setup.PostLink},
		{"provision step", cfg.Setup.Provision},
	}
	seen := map[string]bool{}
	for _, l := range lists {
		for i, s := range l.steps {
			isCheck := l.kind == "health check"
			switch {
			case !stepName.MatchString(s.Name):
				return fmt.Errorf("%s %d: name %q must be kebab-case", l.kind, i+1, s.Name)
			case seen[s.Name]:
				return fmt.Errorf("%s %q: name is already used in this module", l.kind, s.Name)
			case isCheck && (s.Check == "" || s.Run != ""):
				return fmt.Errorf("%s %q: needs a check and no run", l.kind, s.Name)
			case !isCheck && s.Run == "":
				return fmt.Errorf("%s %q: needs a run", l.kind, s.Name)
			}
			seen[s.Name] = true
		}
	}
	return nil
}
