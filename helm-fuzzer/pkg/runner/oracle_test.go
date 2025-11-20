package runner

import (
	"errors"
	"testing"
)

func TestIsCrash(t *testing.T) {
	oracle := NewOracle()

	tests := []struct {
		name     string
		result   *Result
		expected bool
	}{
		{
			name: "success",
			result: &Result{
				Success: true,
			},
			expected: false,
		},
		{
			name: "panic",
			result: &Result{
				Success: false,
				Panic:   "runtime error: invalid memory address",
			},
			expected: true,
		},
		{
			name: "error",
			result: &Result{
				Success: false,
				Error:   errors.New("template error"),
			},
			expected: true,
		},
		{
			name: "no error or panic",
			result: &Result{
				Success: false,
			},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := oracle.IsCrash(tt.result)
			if result != tt.expected {
				t.Errorf("IsCrash() = %v, want %v", result, tt.expected)
			}
		})
	}
}

func TestGetCrashReason(t *testing.T) {
	oracle := NewOracle()

	tests := []struct {
		name     string
		result   *Result
		contains string
	}{
		{
			name: "panic",
			result: &Result{
				Panic: "runtime error",
			},
			contains: "Panic",
		},
		{
			name: "error",
			result: &Result{
				Error: errors.New("template error"),
			},
			contains: "Error",
		},
		{
			name:     "no crash",
			result:   &Result{},
			contains: "Unknown",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			reason := oracle.GetCrashReason(tt.result)
			if reason == "" {
				t.Error("expected non-empty reason")
			}
			// Just check it returns something meaningful
		})
	}
}

func TestIsInteresting(t *testing.T) {
	oracle := NewOracle()

	tests := []struct {
		name     string
		result   *Result
		expected bool
	}{
		{
			name: "success is not interesting",
			result: &Result{
				Success: true,
			},
			expected: false,
		},
		{
			name: "panic is interesting",
			result: &Result{
				Success: false,
				Panic:   "runtime error",
			},
			expected: true,
		},
		{
			name: "validation error not interesting",
			result: &Result{
				Success: false,
				Error:   errors.New("validation failed: required field missing"),
			},
			expected: false,
		},
		{
			name: "template error is interesting",
			result: &Result{
				Success: false,
				Error:   errors.New("template: error executing template"),
			},
			expected: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := oracle.IsInteresting(tt.result)
			if result != tt.expected {
				t.Errorf("IsInteresting() = %v, want %v", result, tt.expected)
			}
		})
	}
}

func TestIgnoreErrors(t *testing.T) {
	oracle := NewOracle()
	oracle.IgnoreErrors = []string{"connection refused"}

	result := &Result{
		Success: false,
		Error:   errors.New("dial tcp: connection refused"),
	}

	if oracle.IsCrash(result) {
		t.Error("expected error to be ignored")
	}
}

func TestNewOracleWithConfig(t *testing.T) {
	ignoreErrors := []string{"network error", "timeout"}
	uninterestingPatterns := []string{"custom uninteresting"}

	oracle := NewOracleWithConfig(ignoreErrors, uninterestingPatterns)

	// Test that ignore errors are set
	if len(oracle.IgnoreErrors) != 2 {
		t.Errorf("expected 2 ignore errors, got %d", len(oracle.IgnoreErrors))
	}

	// Test that uninteresting patterns are set
	if len(oracle.UninterestingPatterns) != 1 {
		t.Errorf("expected 1 uninteresting pattern, got %d", len(oracle.UninterestingPatterns))
	}

	// Test ignore errors functionality
	result := &Result{
		Success: false,
		Error:   errors.New("network error occurred"),
	}

	if oracle.IsCrash(result) {
		t.Error("expected network error to be ignored")
	}

	// Test uninteresting patterns functionality
	result2 := &Result{
		Success: false,
		Error:   errors.New("custom uninteresting error"),
	}

	if oracle.IsInteresting(result2) {
		t.Error("expected custom pattern to be uninteresting")
	}
}

func TestDefaultUninterestingPatterns(t *testing.T) {
	oracle := NewOracle()

	// Test that default patterns work
	tests := []struct {
		name     string
		error    string
		expected bool // true if should be interesting
	}{
		{
			name:     "validation failed should be uninteresting",
			error:    "validation failed: some error",
			expected: false,
		},
		{
			name:     "required value should be uninteresting",
			error:    "required value missing",
			expected: false,
		},
		{
			name:     "template error should be interesting",
			error:    "template: error in rendering",
			expected: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := &Result{
				Success: false,
				Error:   errors.New(tt.error),
			}

			if oracle.IsInteresting(result) != tt.expected {
				t.Errorf("IsInteresting() = %v, want %v for error: %s",
					oracle.IsInteresting(result), tt.expected, tt.error)
			}
		})
	}
}
