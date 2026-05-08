package module

type Module struct {
	Name        string
	Description string
	Path        string
	Links       map[string]string
	Deps        Deps
	Apps        Apps
	Health      []string
	PostLink    []string
	Provision   []string
}

type Deps struct {
	Brew []string
}

type Apps struct {
	Cask []string
}
