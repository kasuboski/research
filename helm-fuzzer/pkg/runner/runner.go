package runner

import (
	"fmt"
	"os"
	"path/filepath"

	"helm.sh/helm/v3/pkg/action"
	"helm.sh/helm/v3/pkg/chart/loader"
	"helm.sh/helm/v3/pkg/cli"
)

// Result represents the result of a fuzzing run
type Result struct {
	Success bool
	Error   error
	Panic   interface{}
	Values  map[string]interface{}
}

// Runner executes Helm template rendering with fuzzing
type Runner struct {
	chartPath string
	settings  *cli.EnvSettings
}

// New creates a new runner for the given chart path
func New(chartPath string) (*Runner, error) {
	// Verify chart path exists
	if _, err := os.Stat(chartPath); os.IsNotExist(err) {
		return nil, fmt.Errorf("chart path does not exist: %s", chartPath)
	}

	return &Runner{
		chartPath: chartPath,
		settings:  cli.New(),
	}, nil
}

// Run executes a single fuzzing iteration with the given values
func (r *Runner) Run(values map[string]interface{}) *Result {
	result := &Result{
		Values: values,
	}

	// Catch panics
	defer func() {
		if rec := recover(); rec != nil {
			result.Success = false
			result.Panic = rec
			result.Error = fmt.Errorf("PANIC: %v", rec)
		}
	}()

	// Load the chart
	chart, err := loader.Load(r.chartPath)
	if err != nil {
		result.Success = false
		result.Error = fmt.Errorf("failed to load chart: %w", err)
		return result
	}

	// Create action configuration
	actionConfig := new(action.Configuration)
	if err := actionConfig.Init(r.settings.RESTClientGetter(), r.settings.Namespace(), os.Getenv("HELM_DRIVER"), func(format string, v ...interface{}) {}); err != nil {
		result.Success = false
		result.Error = fmt.Errorf("failed to initialize action config: %w", err)
		return result
	}

	// Create install action with dry-run
	client := action.NewInstall(actionConfig)
	client.DryRun = true
	client.ClientOnly = true // Don't connect to cluster
	client.ReleaseName = "fuzz-test"
	client.Replace = true
	client.Namespace = "default"

	// Run the installation (dry-run)
	_, err = client.Run(chart, values)
	if err != nil {
		result.Success = false
		result.Error = err
		return result
	}

	result.Success = true
	return result
}

// BuildDependencies is deprecated - Helm v3 automatically handles dependencies
// during chart loading. This function is kept for backward compatibility but
// is essentially a no-op. Dependencies are built automatically by loader.Load().
func (r *Runner) BuildDependencies() error {
	// Verify chart exists
	chartFile := filepath.Join(r.chartPath, "Chart.yaml")
	if _, err := os.Stat(chartFile); os.IsNotExist(err) {
		return fmt.Errorf("Chart.yaml not found at %s", chartFile)
	}

	// In Helm v3, dependencies are automatically built during chart loading
	// via loader.Load(), which we call in Run() and Validate()
	// No explicit dependency building is needed
	return nil
}

// Validate performs a basic validation of the chart
func (r *Runner) Validate() error {
	// Try to load the chart
	_, err := loader.Load(r.chartPath)
	if err != nil {
		return fmt.Errorf("chart validation failed: %w", err)
	}

	return nil
}
