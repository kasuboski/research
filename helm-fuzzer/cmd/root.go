package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var (
	version = "0.1.0"
)

// rootCmd represents the base command
var rootCmd = &cobra.Command{
	Use:   "helm-fuzz",
	Short: "Automated Property-Based Testing for Helm Charts",
	Long: `Helm Fuzz is a chaos testing tool that automatically detects crashes in Helm charts.
It generates thousands of randomized, valid-schema values.yaml inputs and attempts to
render the chart. If a specific set of values causes the template engine to panic or
produce error messages, the tool identifies it and minimizes the input to the smallest
possible reproduction case.`,
	Version: version,
}

// Execute adds all child commands to the root command and sets flags appropriately.
func Execute() error {
	return rootCmd.Execute()
}

func init() {
	rootCmd.SetVersionTemplate(fmt.Sprintf("helm-fuzz version %s\n", version))
}
