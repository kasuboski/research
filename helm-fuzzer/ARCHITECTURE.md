# Helm Fuzz - Architecture Documentation

## Overview

Helm Fuzz is a property-based testing tool for Helm charts that uses randomized value generation to discover edge cases and crashes in chart templates.

## System Architecture

### High-Level Flow

```
User Input (Chart Path)
    ↓
Configuration Loading (.helmfuzz.yaml)
    ↓
Schema Detection (values.schema.json or values.yaml)
    ↓
Generator Initialization (rapid-based)
    ↓
Fuzzing Loop ────────┐
    ↓                │
Value Generation     │
    ↓                │
Template Rendering   │
    ↓                │
Crash Detection      │
    ↓                │
Continue? ───────────┘
    ↓
Results & Reproduction Files
```

## Component Architecture

### 1. Config Package (`pkg/config`)

**Purpose**: Manages user configuration from `.helmfuzz.yaml`

**Key Types**:
- `Config`: Main configuration structure
- `Constraint`: Value constraint definition

**Responsibilities**:
- Load and parse YAML configuration
- Provide default values
- Check if paths should be ignored
- Retrieve constraints for paths

**Design Decisions**:
- Sensible defaults (1000 iterations, depth 5)
- Graceful degradation (returns defaults if config missing)
- Path-based configuration for fine-grained control

### 2. Schema Package (`pkg/schema`)

**Purpose**: Detect and represent value schemas for fuzzing

**Key Types**:
- `Schema`: Internal schema representation
- `SchemaType`: Enum for supported types
- `Engine`: Schema detection and conversion

**Responsibilities**:
- Load JSON schemas from `values.schema.json`
- Infer schemas from `values.yaml` structure
- Convert between formats
- Apply configuration constraints

**Design Decisions**:
- Unified schema representation (JSON Schema → Internal → Generator)
- Type inference based on Go types in YAML
- Depth limiting to prevent infinite recursion
- Support for required/optional fields

**Type Inference Rules**:
```
YAML Value          → Inferred Type
"string"            → TypeString
123                 → TypeInteger
3.14                → TypeNumber
true/false          → TypeBoolean
[]                  → TypeArray (items: string by default)
{}                  → TypeObject
nil                 → TypeNull
```

### 3. Generator Package (`pkg/generator`)

**Purpose**: Generate random values conforming to schema constraints

**Key Types**:
- `Generator`: Wraps rapid.Generator with schema awareness

**Responsibilities**:
- Create rapid.Generator for each schema type
- Apply constraints (min/max, pattern, enum)
- Handle nested structures (objects, arrays)
- Randomly omit optional fields
- Respect depth limits

**Design Decisions**:
- Uses `pgregory.net/rapid` for property-based testing
- Depth tracking prevents deep nesting
- Optional field omission (50% chance) to test missing values
- Enum support for constrained string values

**Generator Mapping**:
```
SchemaType     → Rapid Generator
TypeString     → rapid.String() or rapid.StringN() with length constraints
TypeInteger    → rapid.IntRange() with min/max
TypeNumber     → rapid.Float64Range() with min/max
TypeBoolean    → rapid.Bool()
TypeArray      → rapid.Custom() with slice generation
TypeObject     → rapid.Custom() with map generation
TypeEnum       → rapid.IntRange(0, len-1) to index
```

### 4. Runner Package (`pkg/runner`)

**Purpose**: Execute Helm template rendering and detect failures

**Key Types**:
- `Runner`: Helm SDK wrapper
- `Result`: Execution result with crash info
- `Oracle`: Failure detection logic
- `Minimizer`: Reproduction file generation

**Responsibilities**:
- Load Helm charts
- Execute template rendering (dry-run, client-only)
- Catch panics during rendering
- Validate charts
- Determine if results are interesting crashes
- Save reproduction files

**Design Decisions**:
- Panic recovery via `defer recover()`
- ClientOnly mode (no cluster connection)
- DryRun mode (no actual deployment)
- Oracle pattern for failure detection
- Hash-based reproduction filenames

**Crash Detection Logic**:
```go
IsCrash = (Panic != nil) || (Error != nil && not ignored)
IsInteresting = IsCrash && not "validation failed" && not "required value"
```

### 5. TUI Package (`pkg/tui`)

**Purpose**: Provide user feedback during fuzzing

**Key Types**:
- `TUI`: Terminal UI manager

**Responsibilities**:
- Display fuzzing progress
- Show iteration count and rate
- Report crashes in real-time
- Provide final summary
- Support CI mode (minimal output)

**Design Decisions**:
- Simple text-based UI (no ncurses)
- Real-time progress updates
- Emoji indicators for visual clarity
- Quiet mode for CI/CD

### 6. CMD Package (`cmd`)

**Purpose**: Command-line interface

**Key Types**:
- `rootCmd`: Base cobra command
- `fuzzCmd`: Main fuzzing command

**Responsibilities**:
- Parse command-line arguments
- Orchestrate fuzzing workflow
- Handle timeouts
- Manage exit codes

**Command Flow**:
1. Parse arguments and flags
2. Load configuration
3. Initialize schema engine
4. Detect/infer schema
5. Create runner and validate chart
6. Initialize generator
7. Run fuzzing loop with rapid.Check
8. Report results

## Data Flow

### Schema Detection Flow

```
Chart Directory
    ↓
Check for values.schema.json
    ↓ (exists)
Parse JSON Schema
    ↓
Convert to Internal Schema
    ↓
Apply Config Constraints
    ↓
Ready for Generation

    ↓ (not exists)
Load values.yaml
    ↓
Walk YAML tree
    ↓
Infer types from values
    ↓
Build Internal Schema
    ↓
Apply Config Constraints
    ↓
Ready for Generation
```

### Fuzzing Loop Flow

```
rapid.Check() starts
    ↓
Generate random values (Generator.Generate())
    ↓
Pass to Runner.Run(values)
    ↓
Load chart (cached after first load)
    ↓
Create action.Install with DryRun + ClientOnly
    ↓
Execute chart.Run(values) [wrapped in recover()]
    ↓
Return Result{Success, Error, Panic, Values}
    ↓
Oracle.IsCrash(result)?
    ↓ (yes)
Oracle.IsInteresting(result)?
    ↓ (yes)
Minimizer.SaveReproduction(result)
    ↓
t.Fatalf() → triggers rapid's shrinking
    ↓ (no)
Continue to next iteration
```

## Integration Points

### Helm SDK Integration

The runner integrates with Helm v3 SDK through:

```go
action.Configuration → Initialize with nil logger
action.Install → DryRun + ClientOnly mode
chart.Loader → Load chart from filesystem
```

**Key Settings**:
- `DryRun: true` - Don't actually deploy
- `ClientOnly: true` - Don't connect to Kubernetes
- No logger - Suppress Helm output

### Rapid Integration

The generator integrates with rapid through:

```go
rapid.Check(t, func(t *rapid.T) {
    values := generator.Generate().Draw(t, "values")
    result := runner.Run(values)
    if crash {
        t.Fatalf() // Triggers shrinking
    }
})
```

**Shrinking**: When a test fails, rapid automatically tries smaller inputs to find minimal reproduction.

## Error Handling Strategy

### Panic Recovery

```go
defer func() {
    if rec := recover() {
        result.Panic = rec
        result.Error = fmt.Errorf("PANIC: %v", rec)
    }
}()
```

### Error Classification

1. **Chart Load Errors**: Fail fast, can't continue
2. **Template Errors**: Capture and report as crashes
3. **Validation Errors**: May filter as uninteresting
4. **Configuration Errors**: Fail fast with helpful message

## Configuration System

### Configuration Precedence

1. Command-line flags (highest priority)
2. `.helmfuzz.yaml` in chart directory
3. Default values (lowest priority)

### Configuration Example

```yaml
# .helmfuzz.yaml
ignore:
  - "secrets.*"        # Don't fuzz secret values
  - "database.password"

constraints:
  - path: "replicaCount"
    type: "integer"
    min: 0
    max: 10

  - path: "service.type"
    type: "string"
    enum: ["ClusterIP", "NodePort", "LoadBalancer"]

maxDepth: 5
iterations: 2000
```

## Testing Strategy

### Unit Tests

- Config parsing and defaults
- Type inference for all types
- Generator constraint validation
- Oracle crash detection
- Depth limit enforcement

### Integration Tests

- Full fuzzing workflow
- Crash reproduction
- Minimization effectiveness

### Test Chart

A `testdata/buggy-chart` with intentional bugs for testing:
- Nil pointer access
- Missing field checks
- Type mismatches

## Performance Characteristics

### Time Complexity

- **Schema Detection**: O(n) where n is size of values.yaml
- **Value Generation**: O(d * p) where d is depth, p is properties
- **Template Rendering**: O(t) where t is template complexity
- **Per Iteration**: ~10-100ms depending on chart

### Memory Usage

- **Schema**: O(s) where s is schema size
- **Generated Values**: O(d * p) limited by maxDepth
- **Chart Loading**: O(c) where c is chart size (loaded once)

### Scalability

- Single-threaded by design (rapid limitation)
- Could parallelize multiple runners
- Iteration count is main scaling factor

## Deployment Scenarios

### Standalone Binary

```bash
helm-fuzz fuzz ./my-chart
```

### Helm Plugin

```bash
helm fuzz ./my-chart
```

### CI/CD Pipeline

```bash
helm fuzz ./my-chart --ci --timeout 5m --iterations 10000
```

## Future Architecture Considerations

### Potential Enhancements

1. **Coverage Tracking**: Instrument templates to track execution paths
2. **Corpus Management**: Save interesting inputs for regression testing
3. **Mutation-Based Fuzzing**: Mutate existing values instead of pure generation
4. **Distributed Fuzzing**: Run multiple fuzzers in parallel
5. **Smart Generation**: Learn from crashes to guide generation

### Extension Points

- Custom generators for domain-specific values
- Custom oracles for application-specific failures
- Plugin system for chart-specific rules
- Integration with Helm test framework

## Conclusion

The architecture balances simplicity with effectiveness. The modular design allows for future enhancements while keeping the core fuzzing loop fast and reliable. The integration with rapid provides powerful property-based testing capabilities, while the Helm SDK integration ensures realistic template rendering.
