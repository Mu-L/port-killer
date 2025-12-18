//go:build darwin

package config

import (
	"encoding/json"
	"os"
	"path/filepath"

	"howett.net/plist"
)

const plistPath = "Library/Preferences/com.portkiller.app.plist"

// plistConfig represents the structure of the GUI's plist file
type plistConfig struct {
	FavoritesV2  []int    `plist:"favoritesV2"`
	WatchedPorts []string `plist:"watchedPorts"` // JSON strings
}

type darwinStore struct {
	path string
}

func newPlatformStore() Store {
	home, _ := os.UserHomeDir()
	return &darwinStore{
		path: filepath.Join(home, plistPath),
	}
}

func (s *darwinStore) Load() (*Config, error) {
	cfg := &Config{
		Favorites:    []int{},
		WatchedPorts: []WatchedPort{},
	}

	data, err := os.ReadFile(s.path)
	if err != nil {
		if os.IsNotExist(err) {
			return cfg, nil // Return empty config if file doesn't exist
		}
		return nil, err
	}

	var plistCfg plistConfig
	_, err = plist.Unmarshal(data, &plistCfg)
	if err != nil {
		return nil, err
	}

	// Copy favorites
	cfg.Favorites = plistCfg.FavoritesV2

	// Parse watched ports from JSON strings
	for _, jsonStr := range plistCfg.WatchedPorts {
		var wp WatchedPort
		if err := json.Unmarshal([]byte(jsonStr), &wp); err == nil {
			cfg.WatchedPorts = append(cfg.WatchedPorts, wp)
		}
	}

	return cfg, nil
}

func (s *darwinStore) Save(cfg *Config) error {
	// Read existing plist to preserve other settings
	existingData, err := os.ReadFile(s.path)
	var existing map[string]interface{}

	if err == nil {
		plist.Unmarshal(existingData, &existing)
	} else {
		existing = make(map[string]interface{})
	}

	// Update favorites
	existing["favoritesV2"] = cfg.Favorites

	// Convert watched ports to JSON strings
	watchedJSON := make([]string, 0, len(cfg.WatchedPorts))
	for _, wp := range cfg.WatchedPorts {
		jsonBytes, err := json.Marshal(wp)
		if err == nil {
			watchedJSON = append(watchedJSON, string(jsonBytes))
		}
	}
	existing["watchedPorts"] = watchedJSON

	// Write back
	data, err := plist.MarshalIndent(existing, plist.XMLFormat, "\t")
	if err != nil {
		return err
	}

	return os.WriteFile(s.path, data, 0644)
}
