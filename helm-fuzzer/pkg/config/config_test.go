package config

import (
	"os"
	"path/filepath"
	"testing"
)

func TestDefaultConfig(t *testing.T) {
	cfg := DefaultConfig()

	if cfg.MaxDepth != 5 {
		t.Errorf("expected MaxDepth=5, got %d", cfg.MaxDepth)
	}

	if cfg.Iterations != 1000 {
		t.Errorf("expected Iterations=1000, got %d", cfg.Iterations)
	}

	if len(cfg.Ignore) != 0 {
		t.Errorf("expected empty Ignore list, got %d items", len(cfg.Ignore))
	}
}

func TestLoadConfig_NoFile(t *testing.T) {
	// Create temp directory without config file
	tmpDir := t.TempDir()

	cfg, err := LoadConfig(tmpDir)
	if err != nil {
		t.Fatalf("expected no error when config file missing, got: %v", err)
	}

	// Should return default config
	if cfg.MaxDepth != 5 {
		t.Errorf("expected default MaxDepth=5, got %d", cfg.MaxDepth)
	}
}

func TestLoadConfig_WithFile(t *testing.T) {
	// Create temp directory with config file
	tmpDir := t.TempDir()

	configContent := `
maxDepth: 10
iterations: 500
ignore:
  - "database.password"
  - "api.key"
constraints:
  - path: "service.port"
    type: "integer"
    min: 1
    max: 65535
`

	configPath := filepath.Join(tmpDir, ".helmfuzz.yaml")
	if err := os.WriteFile(configPath, []byte(configContent), 0644); err != nil {
		t.Fatalf("failed to write test config: %v", err)
	}

	cfg, err := LoadConfig(tmpDir)
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}

	if cfg.MaxDepth != 10 {
		t.Errorf("expected MaxDepth=10, got %d", cfg.MaxDepth)
	}

	if cfg.Iterations != 500 {
		t.Errorf("expected Iterations=500, got %d", cfg.Iterations)
	}

	if len(cfg.Ignore) != 2 {
		t.Errorf("expected 2 ignore entries, got %d", len(cfg.Ignore))
	}

	if len(cfg.Constraints) != 1 {
		t.Errorf("expected 1 constraint, got %d", len(cfg.Constraints))
	}
}

func TestIsIgnored(t *testing.T) {
	cfg := &Config{
		Ignore: []string{"database.password", "api.key"},
	}

	tests := []struct {
		path     string
		expected bool
	}{
		{"database.password", true},
		{"api.key", true},
		{"service.port", false},
		{"", false},
	}

	for _, tt := range tests {
		result := cfg.IsIgnored(tt.path)
		if result != tt.expected {
			t.Errorf("IsIgnored(%q) = %v, want %v", tt.path, result, tt.expected)
		}
	}
}

func TestGetConstraint(t *testing.T) {
	min := 1
	max := 65535

	cfg := &Config{
		Constraints: []Constraint{
			{
				Path: "service.port",
				Type: "integer",
				Min:  &min,
				Max:  &max,
			},
		},
	}

	// Test existing constraint
	constraint := cfg.GetConstraint("service.port")
	if constraint == nil {
		t.Fatal("expected constraint, got nil")
	}

	if constraint.Type != "integer" {
		t.Errorf("expected type=integer, got %s", constraint.Type)
	}

	// Test non-existing constraint
	constraint = cfg.GetConstraint("nonexistent")
	if constraint != nil {
		t.Errorf("expected nil constraint, got %v", constraint)
	}
}
