package runner

import (
	"crypto/sha256"
	"fmt"
	"os"
	"path/filepath"

	"gopkg.in/yaml.v3"
)

// Minimizer handles shrinking failing inputs and saving reproduction files
type Minimizer struct {
	outputDir string
}

// NewMinimizer creates a new minimizer
func NewMinimizer(outputDir string) *Minimizer {
	return &Minimizer{
		outputDir: outputDir,
	}
}

// SaveReproduction saves a failing input to a reproduction file
func (m *Minimizer) SaveReproduction(result *Result, reason string) (string, error) {
	// Generate hash of the values for unique filename
	hash := m.hashValues(result.Values)

	filename := fmt.Sprintf("fuzzer-repro-%s.yaml", hash[:8])
	filepath := filepath.Join(m.outputDir, filename)

	// Create output directory if it doesn't exist
	if err := os.MkdirAll(m.outputDir, 0755); err != nil {
		return "", fmt.Errorf("failed to create output directory: %w", err)
	}

	// Add comment header with crash information
	header := fmt.Sprintf("# Helm Fuzz Reproduction Case\n# Crash Reason: %s\n# To reproduce: helm install --dry-run <chart> -f %s\n\n", reason, filename)

	// Marshal values to YAML
	data, err := yaml.Marshal(result.Values)
	if err != nil {
		return "", fmt.Errorf("failed to marshal values: %w", err)
	}

	// Write to file
	content := []byte(header + string(data))
	if err := os.WriteFile(filepath, content, 0644); err != nil {
		return "", fmt.Errorf("failed to write reproduction file: %w", err)
	}

	return filepath, nil
}

// hashValues generates a hash of the values map
func (m *Minimizer) hashValues(values map[string]interface{}) string {
	// Marshal to YAML for consistent hashing
	data, err := yaml.Marshal(values)
	if err != nil {
		// Fallback to simple hash
		return fmt.Sprintf("%x", sha256.Sum256([]byte(fmt.Sprintf("%v", values))))
	}

	hash := sha256.Sum256(data)
	return fmt.Sprintf("%x", hash)
}

// MinimizeInput attempts to minimize a failing input
// This is primarily handled by rapid's built-in shrinking,
// but this function provides a hook for future enhancements
func (m *Minimizer) MinimizeInput(values map[string]interface{}, testFunc func(map[string]interface{}) bool) map[string]interface{} {
	// For now, rely on rapid's built-in shrinking
	// Future: implement custom minimization strategies
	return values
}
