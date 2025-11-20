package tui

import (
	"fmt"
	"io"
	"os"
	"time"
)

// TUI handles the text user interface for fuzzing progress
type TUI struct {
	writer     io.Writer
	startTime  time.Time
	iterations int
	crashes    int
	ciMode     bool
	quiet      bool
}

// New creates a new TUI
func New(ciMode bool) *TUI {
	return &TUI{
		writer:     os.Stdout,
		startTime:  time.Now(),
		iterations: 0,
		crashes:    0,
		ciMode:     ciMode,
		quiet:      ciMode,
	}
}

// Start initializes the TUI display
func (t *TUI) Start(chartName string, maxIterations int) {
	if t.quiet {
		return
	}

	fmt.Fprintf(t.writer, "🔍 Helm Fuzz - Starting fuzzing session\n")
	fmt.Fprintf(t.writer, "📊 Chart: %s\n", chartName)
	fmt.Fprintf(t.writer, "🎯 Target iterations: %d\n", maxIterations)
	fmt.Fprintf(t.writer, "⏰ Started at: %s\n\n", t.startTime.Format("15:04:05"))
}

// Update updates the progress display
func (t *TUI) Update(iteration int, crashed bool) {
	t.iterations = iteration
	if crashed {
		t.crashes++
	}

	if t.quiet {
		return
	}

	// Clear line and print progress
	elapsed := time.Since(t.startTime)
	rate := float64(iteration) / elapsed.Seconds()

	fmt.Fprintf(t.writer, "\r⏳ Iterations: %d | 💥 Crashes: %d | ⚡ Rate: %.1f/s | ⏱️  Elapsed: %s",
		iteration, t.crashes, rate, formatDuration(elapsed))
}

// ReportCrash reports a crash finding
func (t *TUI) ReportCrash(iteration int, reason string, reproFile string) {
	if !t.quiet {
		fmt.Fprintf(t.writer, "\n\n")
	}

	fmt.Fprintf(t.writer, "💥 CRASH DETECTED at iteration %d\n", iteration)
	fmt.Fprintf(t.writer, "   Reason: %s\n", reason)
	if reproFile != "" {
		fmt.Fprintf(t.writer, "   Reproduction file: %s\n", reproFile)
	}

	if !t.quiet {
		fmt.Fprintf(t.writer, "\n")
	}
}

// Finish completes the TUI display
func (t *TUI) Finish() {
	if !t.quiet {
		fmt.Fprintf(t.writer, "\n\n")
	}

	elapsed := time.Since(t.startTime)
	fmt.Fprintf(t.writer, "✅ Fuzzing session completed\n")
	fmt.Fprintf(t.writer, "   Total iterations: %d\n", t.iterations)
	fmt.Fprintf(t.writer, "   Total crashes: %d\n", t.crashes)
	fmt.Fprintf(t.writer, "   Duration: %s\n", formatDuration(elapsed))

	if t.crashes == 0 {
		fmt.Fprintf(t.writer, "\n🎉 No crashes found! Your chart is robust.\n")
	} else {
		fmt.Fprintf(t.writer, "\n⚠️  Found %d crash(es). Please review the reproduction files.\n", t.crashes)
	}
}

// SetWriter sets a custom writer (useful for testing)
func (t *TUI) SetWriter(w io.Writer) {
	t.writer = w
}

// GetCrashCount returns the number of crashes found
func (t *TUI) GetCrashCount() int {
	return t.crashes
}

// formatDuration formats a duration in a human-readable way
func formatDuration(d time.Duration) string {
	if d < time.Minute {
		return fmt.Sprintf("%.1fs", d.Seconds())
	}
	if d < time.Hour {
		return fmt.Sprintf("%.1fm", d.Minutes())
	}
	return fmt.Sprintf("%.1fh", d.Hours())
}

// LogDebug logs debug information (only in non-CI mode)
func (t *TUI) LogDebug(format string, args ...interface{}) {
	if t.ciMode || t.quiet {
		return
	}
	fmt.Fprintf(t.writer, "🔧 "+format+"\n", args...)
}

// LogWarning logs a warning message
func (t *TUI) LogWarning(format string, args ...interface{}) {
	fmt.Fprintf(t.writer, "⚠️  "+format+"\n", args...)
}

// LogError logs an error message
func (t *TUI) LogError(format string, args ...interface{}) {
	fmt.Fprintf(t.writer, "❌ "+format+"\n", args...)
}
