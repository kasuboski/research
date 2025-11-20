# Changelog

## [Unreleased]

### Fixed
- **BuildDependencies Function**: Removed duplicate Chart.yaml check and simplified the function. Helm v3 automatically handles dependencies during chart loading, so this function is now essentially a no-op with proper documentation explaining this behavior.

- **Pattern Matching in Generator**: Added robust error handling for regex pattern generation. The generator now gracefully falls back to regular string generation if pattern matching fails, preventing crashes from complex or unsupported regex patterns.

- **isRapidError Function**: Enhanced error detection with comprehensive pattern matching. The function now checks for multiple rapid-specific error patterns including stack traces, panic messages, and rapid library imports, providing more accurate detection of expected fuzzing errors vs real errors.

- **Oracle Uninteresting Patterns**: Made uninteresting error patterns configurable via .helmfuzz.yaml. Users can now customize which error patterns should be considered uninteresting through the `uninterestingPatterns` configuration option. The Oracle also now supports `ignoreErrors` configuration for patterns that should be treated as non-crashes.

### Added
- **NewOracleWithConfig**: New constructor for Oracle that accepts configuration for ignore errors and uninteresting patterns.

- **Configuration Options**: Added two new configuration fields:
  - `ignoreErrors`: List of error message patterns to ignore during crash detection
  - `uninterestingPatterns`: List of error patterns considered uninteresting (overrides defaults)

- **Tests**: Added comprehensive tests for the new Oracle configuration functionality:
  - `TestNewOracleWithConfig`: Tests custom configuration
  - `TestDefaultUninterestingPatterns`: Tests default pattern behavior

### Changed
- **BuildDependencies**: Function now includes clear documentation explaining that it's deprecated and kept only for backward compatibility, as Helm v3 handles dependencies automatically.

- **Generator Pattern Handling**: Improved with panic recovery and fallback logic for better reliability with complex regex patterns.

## [0.1.0] - 2025-11-20

### Initial Release
- Property-based fuzzing for Helm charts
- Automatic schema detection and inference
- Crash detection with panic recovery
- Input minimization via rapid
- Configuration via .helmfuzz.yaml
- CI/CD integration support
- Helm plugin packaging
- Comprehensive test coverage
- Full documentation
