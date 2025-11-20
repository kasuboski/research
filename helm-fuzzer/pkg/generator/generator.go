package generator

import (
	"fmt"
	"regexp"

	"pgregory.net/rapid"

	"github.com/kasuboski/helm-fuzzer/pkg/schema"
)

// Generator generates random values based on a schema
type Generator struct {
	schema   *schema.Schema
	maxDepth int
}

// New creates a new generator for the given schema
func New(s *schema.Schema, maxDepth int) *Generator {
	return &Generator{
		schema:   s,
		maxDepth: maxDepth,
	}
}

// Generate returns a rapid generator for map[string]interface{}
func (g *Generator) Generate() *rapid.Generator[map[string]interface{}] {
	return rapid.Custom(func(t *rapid.T) map[string]interface{} {
		return g.generateValue(t, g.schema, 0).(map[string]interface{})
	})
}

// generateValue generates a value based on schema and current depth
func (g *Generator) generateValue(t *rapid.T, s *schema.Schema, depth int) interface{} {
	// Prevent deep recursion
	if depth >= g.maxDepth {
		return g.generateDefault(s)
	}

	// If there's a default value and randomly use it
	if s.Default != nil && rapid.Bool().Draw(t, "use_default") {
		return s.Default
	}

	// Handle enum values first
	if len(s.Enum) > 0 {
		idx := rapid.IntRange(0, len(s.Enum)-1).Draw(t, "enum_idx")
		return s.Enum[idx]
	}

	switch s.Type {
	case schema.TypeString:
		return g.generateString(t, s)
	case schema.TypeInteger:
		return g.generateInteger(t, s)
	case schema.TypeNumber:
		return g.generateNumber(t, s)
	case schema.TypeBoolean:
		return rapid.Bool().Draw(t, "bool")
	case schema.TypeObject:
		return g.generateObject(t, s, depth)
	case schema.TypeArray:
		return g.generateArray(t, s, depth)
	case schema.TypeNull:
		return nil
	case schema.TypeAny:
		return g.generateAny(t, depth)
	default:
		return nil
	}
}

// generateString generates a random string
func (g *Generator) generateString(t *rapid.T, s *schema.Schema) string {
	// Handle pattern constraint
	if s.Pattern != "" {
		// Try to use pattern matching if available
		// Note: rapid.StringMatching has limitations with complex regex patterns
		// If pattern matching fails or is unavailable, we fall back to regular strings
		defer func() {
			if r := recover(); r != nil {
				// Pattern matching failed, ignore and continue with regular generation
			}
		}()

		// Attempt pattern-based generation
		// This works for simple patterns but may not support all regex features
		if str := rapid.StringMatching(s.Pattern).Draw(t, "string_pattern"); str != "" {
			return str
		}

		// Fallback: generate regular string if pattern matching doesn't work
		// Users should use constraints or enum for strict value requirements
	}

	minLen := 0
	maxLen := 100

	if s.MinLength != nil {
		minLen = *s.MinLength
	}
	if s.MaxLength != nil {
		maxLen = *s.MaxLength
	}

	// Ensure valid range
	if minLen > maxLen {
		minLen = maxLen
	}

	length := rapid.IntRange(minLen, maxLen).Draw(t, "string_length")
	return rapid.StringN(length, length, -1).Draw(t, "string")
}

// generateInteger generates a random integer
func (g *Generator) generateInteger(t *rapid.T, s *schema.Schema) int {
	min := -1000
	max := 1000

	if s.Minimum != nil {
		min = int(*s.Minimum)
	}
	if s.Maximum != nil {
		max = int(*s.Maximum)
	}

	// Ensure valid range
	if min > max {
		min = max
	}

	return rapid.IntRange(min, max).Draw(t, "int")
}

// generateNumber generates a random float
func (g *Generator) generateNumber(t *rapid.T, s *schema.Schema) float64 {
	min := -1000.0
	max := 1000.0

	if s.Minimum != nil {
		min = *s.Minimum
	}
	if s.Maximum != nil {
		max = *s.Maximum
	}

	// Ensure valid range
	if min > max {
		min = max
	}

	return rapid.Float64Range(min, max).Draw(t, "float")
}

// generateObject generates a random object
func (g *Generator) generateObject(t *rapid.T, s *schema.Schema, depth int) map[string]interface{} {
	result := make(map[string]interface{})

	if s.Properties == nil {
		return result
	}

	for propName, propSchema := range s.Properties {
		// Check if property is required
		isRequired := false
		for _, req := range s.Required {
			if req == propName {
				isRequired = true
				break
			}
		}

		// If not required, randomly omit it (50% chance)
		if !isRequired && rapid.Bool().Draw(t, fmt.Sprintf("include_%s", propName)) {
			continue
		}

		// Generate value for this property
		result[propName] = g.generateValue(t, propSchema, depth+1)
	}

	return result
}

// generateArray generates a random array
func (g *Generator) generateArray(t *rapid.T, s *schema.Schema, depth int) []interface{} {
	// Generate array length (0-10 elements)
	length := rapid.IntRange(0, 10).Draw(t, "array_length")

	result := make([]interface{}, length)
	for i := 0; i < length; i++ {
		if s.Items != nil {
			result[i] = g.generateValue(t, s.Items, depth+1)
		} else {
			result[i] = ""
		}
	}

	return result
}

// generateAny generates a random value of any type
func (g *Generator) generateAny(t *rapid.T, depth int) interface{} {
	// Choose a random type
	typeChoice := rapid.IntRange(0, 5).Draw(t, "any_type")

	switch typeChoice {
	case 0:
		return rapid.String().Draw(t, "any_string")
	case 1:
		return rapid.Int().Draw(t, "any_int")
	case 2:
		return rapid.Bool().Draw(t, "any_bool")
	case 3:
		return rapid.Float64().Draw(t, "any_float")
	case 4:
		return nil
	default:
		return rapid.String().Draw(t, "any_default")
	}
}

// generateDefault returns the default value for a schema
func (g *Generator) generateDefault(s *schema.Schema) interface{} {
	if s.Default != nil {
		return s.Default
	}

	switch s.Type {
	case schema.TypeString:
		return ""
	case schema.TypeInteger:
		return 0
	case schema.TypeNumber:
		return 0.0
	case schema.TypeBoolean:
		return false
	case schema.TypeObject:
		return make(map[string]interface{})
	case schema.TypeArray:
		return []interface{}{}
	default:
		return nil
	}
}

// ValidatePattern checks if a pattern is valid regex
func ValidatePattern(pattern string) error {
	_, err := regexp.Compile(pattern)
	return err
}
