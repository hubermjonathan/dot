package pathutil

import (
	"os"
	"strings"
)

func ExpandHome(path string) string {
	if strings.HasPrefix(path, "~/") {
		home, err := os.UserHomeDir()
		if err != nil || home == "" {
			return path
		}
		return home + path[1:]
	}
	return path
}
