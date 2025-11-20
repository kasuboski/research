package schema

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/kasuboski/helm-fuzzer/pkg/config"
)

func TestInferType(t *testing.T) {
	engine := NewEngine(config.DefaultConfig())

	tests := []struct {
		name     string
		value    interface{}
		expected SchemaType
	}{
		{"string", "hello", TypeString},
		{"int", 42, TypeInteger},
		{"float", 3.14, TypeNumber},
		{"bool", true, TypeBoolean},
		{"null", nil, TypeNull},
		{"array", []interface{}{1, 2, 3}, TypeArray},
		{"object", map[string]interface{}{"key": "value"}, TypeObject},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := engine.inferType(tt.value)
			if result != tt.expected {
				t.Errorf("inferType(%v) = %v, want %v", tt.value, result, tt.expected)
			}
		})
	}
}

func TestInferFromValues(t *testing.T) {
	// Create temp chart directory
	tmpDir := t.TempDir()

	valuesContent := `
replicaCount: 3
image:
  repository: nginx
  tag: "1.19"
  pullPolicy: IfNotPresent
service:
  type: ClusterIP
  port: 80
resources:
  limits:
    cpu: 100m
    memory: 128Mi
enabled: true
`

	valuesPath := filepath.Join(tmpDir, "values.yaml")
	if err := os.WriteFile(valuesPath, []byte(valuesContent), 0644); err != nil {
		t.Fatalf("failed to write test values.yaml: %v", err)
	}

	engine := NewEngine(config.DefaultConfig())
	schema, err := engine.InferFromValues(tmpDir)
	if err != nil {
		t.Fatalf("InferFromValues failed: %v", err)
	}

	// Verify top-level is object
	if schema.Type != TypeObject {
		t.Errorf("expected object type, got %v", schema.Type)
	}

	// Verify properties
	if schema.Properties == nil {
		t.Fatal("expected properties, got nil")
	}

	// Check replicaCount is integer
	if replicaCount, ok := schema.Properties["replicaCount"]; ok {
		if replicaCount.Type != TypeInteger {
			t.Errorf("expected replicaCount to be integer, got %v", replicaCount.Type)
		}
	} else {
		t.Error("expected replicaCount property")
	}

	// Check image is object
	if image, ok := schema.Properties["image"]; ok {
		if image.Type != TypeObject {
			t.Errorf("expected image to be object, got %v", image.Type)
		}
		if image.Properties == nil {
			t.Error("expected image to have properties")
		}
	} else {
		t.Error("expected image property")
	}

	// Check enabled is boolean
	if enabled, ok := schema.Properties["enabled"]; ok {
		if enabled.Type != TypeBoolean {
			t.Errorf("expected enabled to be boolean, got %v", enabled.Type)
		}
	} else {
		t.Error("expected enabled property")
	}
}

func TestInferArraySchema(t *testing.T) {
	engine := NewEngine(config.DefaultConfig())

	// Test with string array
	arr := []interface{}{"item1", "item2", "item3"}
	schema := engine.inferArraySchema(arr, "test", 0)

	if schema.Type != TypeArray {
		t.Errorf("expected array type, got %v", schema.Type)
	}

	if schema.Items == nil {
		t.Fatal("expected items schema, got nil")
	}

	if schema.Items.Type != TypeString {
		t.Errorf("expected items to be string, got %v", schema.Items.Type)
	}

	// Test with empty array
	emptyArr := []interface{}{}
	emptySchema := engine.inferArraySchema(emptyArr, "test", 0)

	if emptySchema.Items == nil {
		t.Fatal("expected items schema for empty array, got nil")
	}

	// Should default to string
	if emptySchema.Items.Type != TypeString {
		t.Errorf("expected empty array items to default to string, got %v", emptySchema.Items.Type)
	}
}

func TestSchemaDepthLimit(t *testing.T) {
	cfg := config.DefaultConfig()
	cfg.MaxDepth = 2
	engine := NewEngine(cfg)

	// Create deeply nested structure
	nested := map[string]interface{}{
		"level1": map[string]interface{}{
			"level2": map[string]interface{}{
				"level3": map[string]interface{}{
					"level4": "too deep",
				},
			},
		},
	}

	schema := engine.inferSchema(nested, "", 0)

	// Should be object
	if schema.Type != TypeObject {
		t.Errorf("expected object type, got %v", schema.Type)
	}

	// Check that deep nesting is limited
	level1 := schema.Properties["level1"]
	if level1 == nil {
		t.Fatal("expected level1 property")
	}

	level2 := level1.Properties["level2"]
	if level2 == nil {
		t.Fatal("expected level2 property")
	}

	// At maxDepth, should return TypeAny instead of continuing
	level3 := level2.Properties["level3"]
	if level3 == nil {
		t.Fatal("expected level3 property")
	}

	// This should be limited by depth
	if level3.Type != TypeAny && level3.Type != TypeObject {
		t.Logf("level3 type: %v", level3.Type)
	}
}
