package module

import (
	"os"
	"path/filepath"

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
	Checks []string `toml:"checks"`
}

type tomlSetup struct {
	PostLink  []string `toml:"post_link"`
	Provision []string `toml:"provision"`
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
	}, nil
}
