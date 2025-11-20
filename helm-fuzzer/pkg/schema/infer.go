package schema

import (
	"fmt"
	"os"
	"path/filepath"
	"reflect"

	"gopkg.in/yaml.v3"
)

// InferFromValues infers schema from values.yaml
func (e *Engine) InferFromValues(chartPath string) (*Schema, error) {
	valuesPath := filepath.Join(chartPath, "values.yaml")

	data, err := os.ReadFile(valuesPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read values.yaml: %w", err)
	}

	var values map[string]interface{}
	if err := yaml.Unmarshal(data, &values); err != nil {
		return nil, fmt.Errorf("failed to parse values.yaml: %w", err)
	}

	return e.inferSchema(values, "", 0), nil
}

// inferSchema recursively infers schema from a value
func (e *Engine) inferSchema(value interface{}, path string, depth int) *Schema {
	// Prevent infinite recursion
	if depth > e.config.MaxDepth {
		return &Schema{Type: TypeAny}
	}

	// Check if this path should be ignored
	if path != "" && e.config.IsIgnored(path) {
		return &Schema{
			Type:    e.inferType(value),
			Default: value,
		}
	}

	// Check for constraint override
	if path != "" {
		if constraint := e.config.GetConstraint(path); constraint != nil {
			return e.schemaFromConstraint(constraint, value)
		}
	}

	// Infer based on value type
	switch v := value.(type) {
	case map[string]interface{}:
		return e.inferObjectSchema(v, path, depth)
	case []interface{}:
		return e.inferArraySchema(v, path, depth)
	default:
		return e.inferPrimitiveSchema(value)
	}
}

// inferObjectSchema infers schema for an object
func (e *Engine) inferObjectSchema(obj map[string]interface{}, path string, depth int) *Schema {
	schema := &Schema{
		Type:       TypeObject,
		Properties: make(map[string]*Schema),
		Required:   []string{},
	}

	for key, value := range obj {
		propPath := path
		if propPath != "" {
			propPath += "."
		}
		propPath += key

		schema.Properties[key] = e.inferSchema(value, propPath, depth+1)

		// Mark non-nil values as not required by default
		// This allows the fuzzer to test with missing fields
		// Users can override via .helmfuzz.yaml if needed
	}

	return schema
}

// inferArraySchema infers schema for an array
func (e *Engine) inferArraySchema(arr []interface{}, path string, depth int) *Schema {
	schema := &Schema{
		Type: TypeArray,
	}

	if len(arr) == 0 {
		// Empty array - default to string array with warning
		schema.Items = &Schema{Type: TypeString}
		return schema
	}

	// Infer from first element
	itemPath := path + "[]"
	schema.Items = e.inferSchema(arr[0], itemPath, depth+1)

	return schema
}

// inferPrimitiveSchema infers schema for primitive types
func (e *Engine) inferPrimitiveSchema(value interface{}) *Schema {
	schema := &Schema{
		Type:    e.inferType(value),
		Default: value,
	}
	return schema
}

// inferType infers the schema type from a Go value
func (e *Engine) inferType(value interface{}) SchemaType {
	if value == nil {
		return TypeNull
	}

	switch value.(type) {
	case bool:
		return TypeBoolean
	case int, int8, int16, int32, int64, uint, uint8, uint16, uint32, uint64:
		return TypeInteger
	case float32, float64:
		return TypeNumber
	case string:
		return TypeString
	case []interface{}:
		return TypeArray
	case map[string]interface{}:
		return TypeObject
	default:
		// Check using reflection for other numeric types
		rv := reflect.ValueOf(value)
		switch rv.Kind() {
		case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
			return TypeInteger
		case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
			return TypeInteger
		case reflect.Float32, reflect.Float64:
			return TypeNumber
		case reflect.Bool:
			return TypeBoolean
		case reflect.String:
			return TypeString
		case reflect.Slice, reflect.Array:
			return TypeArray
		case reflect.Map:
			return TypeObject
		default:
			return TypeAny
		}
	}
}

// schemaFromConstraint creates a schema from a config constraint
func (e *Engine) schemaFromConstraint(constraint *config.Constraint, defaultValue interface{}) *Schema {
	schema := &Schema{
		Type:    SchemaType(constraint.Type),
		Default: defaultValue,
	}

	if constraint.Min != nil {
		min := float64(*constraint.Min)
		schema.Minimum = &min
	}

	if constraint.Max != nil {
		max := float64(*constraint.Max)
		schema.Maximum = &max
	}

	if constraint.Pattern != "" {
		schema.Pattern = constraint.Pattern
	}

	if len(constraint.Enum) > 0 {
		schema.Enum = constraint.Enum
	}

	return schema
}
