package config

import (
	"os"
	"path/filepath"

	"gopkg.in/yaml.v3"
)

// Config represents the .helmfuzz.yaml configuration file
type Config struct {
	// Ignore lists JSON paths to skip during fuzzing
	Ignore []string `yaml:"ignore"`
	// Constraints defines value constraints for specific paths
	Constraints []Constraint `yaml:"constraints"`
	// MaxDepth limits recursion depth (default: 5)
	MaxDepth int `yaml:"maxDepth"`
	// Iterations number of fuzz iterations (default: 1000)
	Iterations int `yaml:"iterations"`
	// IgnoreErrors lists error message patterns to ignore during crash detection
	IgnoreErrors []string `yaml:"ignoreErrors,omitempty"`
	// UninterestingPatterns lists error patterns considered uninteresting
	UninterestingPatterns []string `yaml:"uninterestingPatterns,omitempty"`
	// KubeVersions lists Kubernetes versions to test against (default: ["1.28.0", "1.29.0", "1.30.0", "1.31.0"])
	KubeVersions []string `yaml:"kubeVersions,omitempty"`
}

// Constraint defines constraints for a specific value path
type Constraint struct {
	// Path is the JSON path (e.g., "service.port")
	Path string `yaml:"path"`
	// Type is the value type ("int", "string", "bool", etc.)
	Type string `yaml:"type"`
	// Min is the minimum value for numeric types
	Min *int `yaml:"min,omitempty"`
	// Max is the maximum value for numeric types
	Max *int `yaml:"max,omitempty"`
	// Pattern is a regex pattern for string types
	Pattern string `yaml:"pattern,omitempty"`
	// Enum lists allowed values
	Enum []interface{} `yaml:"enum,omitempty"`
	// Required indicates if this field must be present
	Required bool `yaml:"required,omitempty"`
}

// DefaultConfig returns a config with sensible defaults
func DefaultConfig() *Config {
	return &Config{
		Ignore:       []string{},
		Constraints:  []Constraint{},
		MaxDepth:     5,
		Iterations:   1000,
		KubeVersions: []string{"1.28.0", "1.29.0", "1.30.0", "1.31.0"},
	}
}

// LoadConfig loads configuration from a .helmfuzz.yaml file
// If the file doesn't exist, returns default config
func LoadConfig(chartPath string) (*Config, error) {
	configPath := filepath.Join(chartPath, ".helmfuzz.yaml")

	// Check if config file exists
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		return DefaultConfig(), nil
	}

	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, err
	}

	config := DefaultConfig()
	if err := yaml.Unmarshal(data, config); err != nil {
		return nil, err
	}

	// Apply defaults if not set
	if config.MaxDepth == 0 {
		config.MaxDepth = 5
	}
	if config.Iterations == 0 {
		config.Iterations = 1000
	}
	if len(config.KubeVersions) == 0 {
		config.KubeVersions = []string{"1.28.0", "1.29.0", "1.30.0", "1.31.0"}
	}

	return config, nil
}

// IsIgnored checks if a given path should be ignored
func (c *Config) IsIgnored(path string) bool {
	for _, ignored := range c.Ignore {
		if ignored == path {
			return true
		}
	}
	return false
}

// GetConstraint returns the constraint for a given path, if any
func (c *Config) GetConstraint(path string) *Constraint {
	for i := range c.Constraints {
		if c.Constraints[i].Path == path {
			return &c.Constraints[i]
		}
	}
	return nil
}
