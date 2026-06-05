package linker

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"os"
	"path/filepath"
	"time"
)

type Result int

const (
	Created Result = iota
	Skipped
	Replaced
)

type Status int

const (
	StatusOK Status = iota
	StatusBroken
	StatusMissing
	StatusWrongTarget
	StatusNotSymlink
)

func Link(source, target, backupDir string) (Result, error) {
	if err := os.MkdirAll(filepath.Dir(target), 0755); err != nil {
		return 0, err
	}

	info, err := os.Lstat(target)
	if err == nil {
		if info.Mode()&os.ModeSymlink != 0 {
			existing, _ := os.Readlink(target)
			if existing == source {
				return Skipped, nil
			}
			if err := os.Remove(target); err != nil {
				return 0, err
			}
			return createLink(source, target, Replaced)
		}
		if backupDir != "" {
			if err := backup(target, backupDir); err != nil {
				return 0, fmt.Errorf("backup failed: %w", err)
			}
		} else if err := os.Remove(target); err != nil {
			return 0, err
		}
		return createLink(source, target, Replaced)
	}

	if !os.IsNotExist(err) {
		return 0, err
	}

	return createLink(source, target, Created)
}

func createLink(source, target string, result Result) (Result, error) {
	if err := os.Symlink(source, target); err != nil {
		return 0, err
	}
	return result, nil
}

func Unlink(target string) error {
	info, err := os.Lstat(target)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return err
	}
	if info.Mode()&os.ModeSymlink == 0 {
		return fmt.Errorf("%s is not a symlink", target)
	}
	return os.Remove(target)
}

func Verify(source, target string) Status {
	info, err := os.Lstat(target)
	if err != nil {
		if os.IsNotExist(err) {
			return StatusMissing
		}
		return StatusBroken
	}

	if info.Mode()&os.ModeSymlink == 0 {
		return StatusNotSymlink
	}

	resolved, err := os.Readlink(target)
	if err != nil {
		return StatusBroken
	}

	if resolved != source {
		return StatusWrongTarget
	}

	if _, err := os.Stat(target); err != nil {
		return StatusBroken
	}

	return StatusOK
}

func backup(target, backupDir string) error {
	if err := os.MkdirAll(backupDir, 0755); err != nil {
		return err
	}
	sum := sha256.Sum256([]byte(target))
	hash := hex.EncodeToString(sum[:])[:6]
	stamp := time.Now().UTC().Format("20060102T150405.000000000")
	suffix := stamp + "." + hash
	backupPath := filepath.Join(backupDir, filepath.Base(target)+"."+suffix)
	return os.Rename(target, backupPath)
}
