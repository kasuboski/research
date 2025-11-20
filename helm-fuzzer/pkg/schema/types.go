package schema

import "github.com/kasuboski/helm-fuzzer/pkg/config"

// SchemaType represents the type of a schema field
type SchemaType string

const (
	TypeString  SchemaType = "string"
	TypeInteger SchemaType = "integer"
	TypeNumber  SchemaType = "number"
	TypeBoolean SchemaType = "boolean"
	TypeObject  SchemaType = "object"
	TypeArray   SchemaType = "array"
	TypeNull    SchemaType = "null"
	TypeAny     SchemaType = "any"
)

// Schema represents a value schema that can be used for fuzzing
type Schema struct {
	Type        SchemaType
	Properties  map[string]*Schema // For objects
	Items       *Schema            // For arrays
	Required    []string           // Required property names
	Enum        []interface{}      // Enum values
	Pattern     string             // Regex pattern for strings
	MinLength   *int               // Min length for strings
	MaxLength   *int               // Max length for strings
	Minimum     *float64           // Min value for numbers
	Maximum     *float64           // Max value for numbers
	Default     interface{}        // Default value
	Description string             // Description
}

// Engine handles schema detection and parsing
type Engine struct {
	config *config.Config
}

// NewEngine creates a new schema engine
func NewEngine(cfg *config.Config) *Engine {
	return &Engine{
		config: cfg,
	}
}

// DetectSchema attempts to load schema from values.schema.json,
// falling back to inference from values.yaml
func (e *Engine) DetectSchema(chartPath string) (*Schema, error) {
	// First, try to load JSON schema
	schema, err := e.LoadJSONSchema(chartPath)
	if err == nil {
		return schema, nil
	}

	// Fall back to inference from values.yaml
	return e.InferFromValues(chartPath)
}
