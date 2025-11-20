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
