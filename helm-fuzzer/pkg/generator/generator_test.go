package generator

import (
	"testing"

	"pgregory.net/rapid"

	"github.com/kasuboski/helm-fuzzer/pkg/schema"
)

func TestGenerateString(t *testing.T) {
	sch := &schema.Schema{
		Type: schema.TypeString,
	}

	gen := New(sch, 5)

	rapid.Check(t, func(t *rapid.T) {
		value := gen.generateValue(t, sch, 0)

		// Should be a string
		if _, ok := value.(string); !ok {
			t.Fatalf("expected string, got %T", value)
		}
	})
}

func TestGenerateStringWithConstraints(t *testing.T) {
	minLen := 5
	maxLen := 10

	sch := &schema.Schema{
		Type:      schema.TypeString,
		MinLength: &minLen,
		MaxLength: &maxLen,
	}

	gen := New(sch, 5)

	rapid.Check(t, func(t *rapid.T) {
		value := gen.generateValue(t, sch, 0)

		str, ok := value.(string)
		if !ok {
			t.Fatalf("expected string, got %T", value)
		}

		if len(str) < minLen {
			t.Errorf("string length %d is less than min %d", len(str), minLen)
		}

		if len(str) > maxLen {
			t.Errorf("string length %d is greater than max %d", len(str), maxLen)
		}
	})
}

func TestGenerateInteger(t *testing.T) {
	sch := &schema.Schema{
		Type: schema.TypeInteger,
	}

	gen := New(sch, 5)

	rapid.Check(t, func(t *rapid.T) {
		value := gen.generateValue(t, sch, 0)

		// Should be an integer
		if _, ok := value.(int); !ok {
			t.Fatalf("expected int, got %T", value)
		}
	})
}

func TestGenerateIntegerWithConstraints(t *testing.T) {
	min := 10.0
	max := 100.0

	sch := &schema.Schema{
		Type:    schema.TypeInteger,
		Minimum: &min,
		Maximum: &max,
	}

	gen := New(sch, 5)

	rapid.Check(t, func(t *rapid.T) {
		value := gen.generateValue(t, sch, 0)

		num, ok := value.(int)
		if !ok {
			t.Fatalf("expected int, got %T", value)
		}

		if num < int(min) {
			t.Errorf("value %d is less than min %d", num, int(min))
		}

		if num > int(max) {
			t.Errorf("value %d is greater than max %d", num, int(max))
		}
	})
}

func TestGenerateBoolean(t *testing.T) {
	sch := &schema.Schema{
		Type: schema.TypeBoolean,
	}

	gen := New(sch, 5)

	rapid.Check(t, func(t *rapid.T) {
		value := gen.generateValue(t, sch, 0)

		// Should be a boolean
		if _, ok := value.(bool); !ok {
			t.Fatalf("expected bool, got %T", value)
		}
	})
}

func TestGenerateObject(t *testing.T) {
	sch := &schema.Schema{
		Type: schema.TypeObject,
		Properties: map[string]*schema.Schema{
			"name": {Type: schema.TypeString},
			"age":  {Type: schema.TypeInteger},
		},
	}

	gen := New(sch, 5)

	rapid.Check(t, func(t *rapid.T) {
		value := gen.generateValue(t, sch, 0)

		obj, ok := value.(map[string]interface{})
		if !ok {
			t.Fatalf("expected map[string]interface{}, got %T", value)
		}

		// Properties might be omitted if not required, so we just check types if present
		if name, exists := obj["name"]; exists {
			if _, ok := name.(string); !ok {
				t.Errorf("expected name to be string, got %T", name)
			}
		}

		if age, exists := obj["age"]; exists {
			if _, ok := age.(int); !ok {
				t.Errorf("expected age to be int, got %T", age)
			}
		}
	})
}

func TestGenerateArray(t *testing.T) {
	sch := &schema.Schema{
		Type: schema.TypeArray,
		Items: &schema.Schema{
			Type: schema.TypeString,
		},
	}

	gen := New(sch, 5)

	rapid.Check(t, func(t *rapid.T) {
		value := gen.generateValue(t, sch, 0)

		arr, ok := value.([]interface{})
		if !ok {
			t.Fatalf("expected []interface{}, got %T", value)
		}

		// Check all items are strings
		for i, item := range arr {
			if _, ok := item.(string); !ok {
				t.Errorf("expected item %d to be string, got %T", i, item)
			}
		}
	})
}

func TestGenerateEnum(t *testing.T) {
	sch := &schema.Schema{
		Type: schema.TypeString,
		Enum: []interface{}{"ClusterIP", "NodePort", "LoadBalancer"},
	}

	gen := New(sch, 5)

	rapid.Check(t, func(t *rapid.T) {
		value := gen.generateValue(t, sch, 0)

		str, ok := value.(string)
		if !ok {
			t.Fatalf("expected string, got %T", value)
		}

		// Should be one of the enum values
		valid := false
		for _, enumVal := range sch.Enum {
			if str == enumVal.(string) {
				valid = true
				break
			}
		}

		if !valid {
			t.Errorf("value %q is not in enum %v", str, sch.Enum)
		}
	})
}

func TestGenerateWithDepthLimit(t *testing.T) {
	// Create deeply nested schema
	sch := &schema.Schema{
		Type: schema.TypeObject,
		Properties: map[string]*schema.Schema{
			"nested": {
				Type: schema.TypeObject,
				Properties: map[string]*schema.Schema{
					"deep": {Type: schema.TypeString},
				},
			},
		},
	}

	gen := New(sch, 1) // Limit depth to 1

	rapid.Check(t, func(t *rapid.T) {
		value := gen.generateValue(t, sch, 0)

		obj, ok := value.(map[string]interface{})
		if !ok {
			t.Fatalf("expected map[string]interface{}, got %T", value)
		}

		// Should generate top level, but nested might be limited
		_ = obj
	})
}

func TestGenerateRequiredFields(t *testing.T) {
	sch := &schema.Schema{
		Type: schema.TypeObject,
		Properties: map[string]*schema.Schema{
			"required":    {Type: schema.TypeString},
			"notRequired": {Type: schema.TypeString},
		},
		Required: []string{"required"},
	}

	gen := New(sch, 5)

	// Run multiple times to ensure required field is always present
	foundWithoutRequired := false
	foundWithRequired := true

	for i := 0; i < 10; i++ {
		err := rapid.Check(t, func(t *rapid.T) {
			value := gen.generateValue(t, sch, 0)

			obj, ok := value.(map[string]interface{})
			if !ok {
				t.Fatalf("expected map[string]interface{}, got %T", value)
			}

			// Required field should always be present
			if _, exists := obj["required"]; !exists {
				foundWithRequired = false
			}

			// Optional field might not be present
			if _, exists := obj["notRequired"]; !exists {
				foundWithoutRequired = true
			}
		})

		if err == nil {
			break
		}
	}

	if !foundWithRequired {
		t.Error("required field was not always present")
	}
}
