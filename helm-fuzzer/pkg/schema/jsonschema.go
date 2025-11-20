package schema

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	"github.com/invopop/jsonschema"
	"github.com/kasuboski/helm-fuzzer/pkg/config"
)

// LoadJSONSchema loads and parses values.schema.json
func (e *Engine) LoadJSONSchema(chartPath string) (*Schema, error) {
	schemaPath := filepath.Join(chartPath, "values.schema.json")

	// Check if file exists
	if _, err := os.Stat(schemaPath); os.IsNotExist(err) {
		return nil, err
	}

	data, err := os.ReadFile(schemaPath)
	if err != nil {
		return nil, err
	}

	var jsonSchema jsonschema.Schema
	if err := json.Unmarshal(data, &jsonSchema); err != nil {
		return nil, err
	}

	return e.convertJSONSchema(&jsonSchema, ""), nil
}

// convertJSONSchema converts a JSON schema to our internal Schema representation
func (e *Engine) convertJSONSchema(js *jsonschema.Schema, path string) *Schema {
	if js == nil {
		return &Schema{Type: TypeAny}
	}

	schema := &Schema{
		Description: js.Description,
	}

	// Handle type
	if len(js.Type) > 0 {
		schema.Type = SchemaType(js.Type)
	} else {
		schema.Type = TypeAny
	}

	// Handle enum
	if len(js.Enum) > 0 {
		schema.Enum = js.Enum
	}

	// Handle pattern
	if js.Pattern != "" {
		schema.Pattern = js.Pattern
	}

	// Handle string constraints
	if js.MinLength != nil {
		minLen := int(*js.MinLength)
		schema.MinLength = &minLen
	}
	if js.MaxLength != nil {
		maxLen := int(*js.MaxLength)
		schema.MaxLength = &maxLen
	}

	// Handle number constraints
	if js.Minimum != "" {
		if minVal, err := js.Minimum.Float64(); err == nil {
			schema.Minimum = &minVal
		}
	}
	if js.Maximum != "" {
		if maxVal, err := js.Maximum.Float64(); err == nil {
			schema.Maximum = &maxVal
		}
	}

	// Handle default
	if js.Default != nil {
		schema.Default = js.Default
	}

	// Handle object properties
	if schema.Type == TypeObject && js.Properties != nil {
		schema.Properties = make(map[string]*Schema)
		for pair := js.Properties.Oldest(); pair != nil; pair = pair.Next() {
			propName := pair.Key
			propSchema := pair.Value

			propPath := path
			if propPath != "" {
				propPath += "."
			}
			propPath += propName

			// Check if this path should be ignored
			if e.config.IsIgnored(propPath) {
				// Use default value for ignored paths
				if propSchema.Default != nil {
					schema.Properties[propName] = &Schema{
						Type:    SchemaType(propSchema.Type),
						Default: propSchema.Default,
					}
				}
				continue
			}

			// Apply constraints from config
			if constraint := e.config.GetConstraint(propPath); constraint != nil {
				propSchema = e.applyConstraint(propSchema, constraint)
			}

			schema.Properties[propName] = e.convertJSONSchema(propSchema, propPath)
		}

		// Handle required fields
		if len(js.Required) > 0 {
			schema.Required = js.Required
		}
	}

	// Handle array items
	if schema.Type == TypeArray {
		if js.Items != nil {
			itemPath := path + "[]"
			schema.Items = e.convertJSONSchema(js.Items, itemPath)
		} else {
			// Default to any type for arrays without item schema
			schema.Items = &Schema{Type: TypeAny}
		}
	}

	return schema
}

// applyConstraint applies a configuration constraint to a JSON schema
func (e *Engine) applyConstraint(js *jsonschema.Schema, constraint *config.Constraint) *jsonschema.Schema {
	// Make a copy to avoid mutating the original
	result := *js

	if constraint.Type != "" {
		result.Type = constraint.Type
	}

	if constraint.Min != nil {
		min := float64(*constraint.Min)
		result.Minimum = json.Number(fmt.Sprintf("%f", min))
	}

	if constraint.Max != nil {
		max := float64(*constraint.Max)
		result.Maximum = json.Number(fmt.Sprintf("%f", max))
	}

	if constraint.Pattern != "" {
		result.Pattern = constraint.Pattern
	}

	if len(constraint.Enum) > 0 {
		result.Enum = constraint.Enum
	}

	return &result
}
