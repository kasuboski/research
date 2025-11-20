package cmd

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/spf13/cobra"
	"pgregory.net/rapid"

	"github.com/kasuboski/helm-fuzzer/pkg/config"
	"github.com/kasuboski/helm-fuzzer/pkg/generator"
	"github.com/kasuboski/helm-fuzzer/pkg/runner"
	"github.com/kasuboski/helm-fuzzer/pkg/schema"
	"github.com/kasuboski/helm-fuzzer/pkg/tui"
)

var (
	ciMode     bool
	timeoutStr string
	iterations int
	outputDir  string
)

// fuzzCmd represents the fuzz command
var fuzzCmd = &cobra.Command{
	Use:   "fuzz <chart-path>",
	Short: "Run fuzzing on a Helm chart",
	Long: `Run property-based fuzzing on a Helm chart by generating randomized
valid inputs and testing template rendering. This helps discover edge cases
that cause crashes or errors in chart templates.`,
	Args: cobra.ExactArgs(1),
	RunE: runFuzz,
}

func init() {
	rootCmd.AddCommand(fuzzCmd)

	fuzzCmd.Flags().BoolVar(&ciMode, "ci", false, "Run in CI mode (non-interactive)")
	fuzzCmd.Flags().StringVar(&timeoutStr, "timeout", "5m", "Timeout for fuzzing session (e.g., 5m, 1h)")
	fuzzCmd.Flags().IntVar(&iterations, "iterations", 0, "Number of iterations (overrides config)")
	fuzzCmd.Flags().StringVar(&outputDir, "output", ".", "Output directory for reproduction files")
}

func runFuzz(cmd *cobra.Command, args []string) error {
	chartPath := args[0]

	// Resolve absolute path
	absPath, err := filepath.Abs(chartPath)
	if err != nil {
		return fmt.Errorf("failed to resolve chart path: %w", err)
	}
	chartPath = absPath

	// Verify chart exists
	if _, err := os.Stat(chartPath); os.IsNotExist(err) {
		return fmt.Errorf("chart path does not exist: %s", chartPath)
	}

	// Parse timeout
	timeout, err := time.ParseDuration(timeoutStr)
	if err != nil {
		return fmt.Errorf("invalid timeout: %w", err)
	}

	// Load configuration
	cfg, err := config.LoadConfig(chartPath)
	if err != nil {
		return fmt.Errorf("failed to load config: %w", err)
	}

	// Override iterations if specified
	if iterations > 0 {
		cfg.Iterations = iterations
	}

	// Initialize TUI
	ui := tui.New(ciMode)
	chartName := filepath.Base(chartPath)
	ui.Start(chartName, cfg.Iterations)

	// Initialize schema engine
	schemaEngine := schema.NewEngine(cfg)

	ui.LogDebug("Detecting schema...")
	sch, err := schemaEngine.DetectSchema(chartPath)
	if err != nil {
		return fmt.Errorf("failed to detect schema: %w", err)
	}
	ui.LogDebug("Schema detected: %s", sch.Type)

	// Initialize runner
	ui.LogDebug("Initializing test runner...")
	testRunner, err := runner.New(chartPath)
	if err != nil {
		return fmt.Errorf("failed to create runner: %w", err)
	}

	// Validate chart
	ui.LogDebug("Validating chart...")
	if err := testRunner.Validate(); err != nil {
		return fmt.Errorf("chart validation failed: %w", err)
	}

	// Initialize oracle and minimizer
	oracle := runner.NewOracle()
	minimizer := runner.NewMinimizer(outputDir)

	// Initialize generator
	gen := generator.New(sch, cfg.MaxDepth)

	// Run fuzzing with timeout
	timeoutChan := time.After(timeout)
	crashFound := false

	ui.LogDebug("Starting fuzzing loop...")

	// Use rapid.Check for property-based testing
	err = rapid.Check(func(t *rapid.T) {
		// Check timeout
		select {
		case <-timeoutChan:
			t.Skip("timeout reached")
		default:
		}

		// Generate values
		values := gen.Generate().Draw(t, "values")

		// Run test
		result := testRunner.Run(values)

		// Update UI
		iteration := t.NumRuns()
		isCrash := oracle.IsCrash(result)
		ui.Update(iteration, isCrash)

		// Check for crash
		if isCrash && oracle.IsInteresting(result) {
			crashFound = true
			reason := oracle.GetCrashReason(result)

			// Save reproduction file
			reproFile, err := minimizer.SaveReproduction(result, reason)
			if err != nil {
				ui.LogWarning("Failed to save reproduction file: %v", err)
			}

			ui.ReportCrash(iteration, reason, reproFile)

			// Fail the test to trigger rapid's shrinking
			t.Fatalf("crash detected: %s", reason)
		}
	})

	ui.Finish()

	// Determine exit code
	if crashFound {
		if ciMode {
			return fmt.Errorf("fuzzing found crashes")
		}
		os.Exit(1)
	}

	if err != nil {
		// If error is not a rapid error, it's a real error
		if !isRapidError(err) {
			return fmt.Errorf("fuzzing failed: %w", err)
		}
	}

	return nil
}

// isRapidError checks if an error is from rapid (expected during fuzzing)
func isRapidError(err error) bool {
	if err == nil {
		return false
	}
	// Rapid errors typically contain "failed after" or similar
	errStr := err.Error()
	return strings.Contains(errStr, "failed") || strings.Contains(errStr, "crash detected")
}
