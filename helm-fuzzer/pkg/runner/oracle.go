package runner

import (
	"strings"
)

// Oracle determines if a test result represents a failure/crash
type Oracle struct {
	// IgnoreErrors lists error message patterns to ignore (treated as non-crashes)
	IgnoreErrors []string
	// UninterestingPatterns lists patterns for crashes that are not interesting
	UninterestingPatterns []string
}

// NewOracle creates a new oracle with default settings
func NewOracle() *Oracle {
	return &Oracle{
		IgnoreErrors:          []string{},
		UninterestingPatterns: getDefaultUninterestingPatterns(),
	}
}

// NewOracleWithConfig creates a new oracle with configuration
func NewOracleWithConfig(ignoreErrors, uninterestingPatterns []string) *Oracle {
	oracle := NewOracle()

	// Merge user-provided patterns with defaults
	if len(ignoreErrors) > 0 {
		oracle.IgnoreErrors = append(oracle.IgnoreErrors, ignoreErrors...)
	}

	if len(uninterestingPatterns) > 0 {
		// Replace defaults with user-provided patterns
		oracle.UninterestingPatterns = uninterestingPatterns
	}

	return oracle
}

// getDefaultUninterestingPatterns returns default patterns for uninteresting errors
func getDefaultUninterestingPatterns() []string {
	return []string{
		"validation failed",
		"required value",
		"missing required field",
	}
}

// IsCrash determines if a result represents a crash
func (o *Oracle) IsCrash(result *Result) bool {
	if result.Success {
		return false
	}

	// Check for panic
	if result.Panic != nil {
		return true
	}

	// Check for errors
	if result.Error != nil {
		// Check if error should be ignored
		for _, ignorePattern := range o.IgnoreErrors {
			if strings.Contains(result.Error.Error(), ignorePattern) {
				return false
			}
		}
		return true
	}

	return false
}

// GetCrashReason returns a human-readable reason for the crash
func (o *Oracle) GetCrashReason(result *Result) string {
	if result.Panic != nil {
		return "Panic: " + formatPanic(result.Panic)
	}

	if result.Error != nil {
		return "Error: " + result.Error.Error()
	}

	return "Unknown failure"
}

// formatPanic formats a panic value as a string
func formatPanic(p interface{}) string {
	if p == nil {
		return "nil"
	}

	switch v := p.(type) {
	case string:
		return v
	case error:
		return v.Error()
	default:
		return "unknown panic type"
	}
}

// IsInteresting determines if a crash is interesting (not a known issue)
func (o *Oracle) IsInteresting(result *Result) bool {
	if !o.IsCrash(result) {
		return false
	}

	// Check for uninteresting errors
	if result.Error != nil {
		errMsg := result.Error.Error()

		// Check against configured uninteresting patterns
		for _, pattern := range o.UninterestingPatterns {
			if strings.Contains(errMsg, pattern) {
				return false
			}
		}
	}

	return true
}
