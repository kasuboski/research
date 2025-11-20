package runner

import (
	"crypto/sha256"
	"fmt"
	"regexp"
	"strings"
)

// Deduplicator tracks seen crashes to avoid reporting duplicates
type Deduplicator struct {
	seen map[string]bool
}

// NewDeduplicator creates a new deduplicator
func NewDeduplicator() *Deduplicator {
	return &Deduplicator{
		seen: make(map[string]bool),
	}
}

// IsDuplicate checks if a crash reason has been seen before
func (d *Deduplicator) IsDuplicate(reason string) bool {
	normalized := d.normalizeReason(reason)
	return d.seen[normalized]
}

// MarkSeen marks a crash reason as seen
func (d *Deduplicator) MarkSeen(reason string) {
	normalized := d.normalizeReason(reason)
	d.seen[normalized] = true
}

// normalizeReason normalizes crash reasons to detect duplicates
// It removes dynamic values like file names, line numbers, and unique IDs
func (d *Deduplicator) normalizeReason(reason string) string {
	// Remove "Error: " or "Panic: " prefix for consistency
	normalized := strings.TrimPrefix(reason, "Error: ")
	normalized = strings.TrimPrefix(normalized, "Panic: ")

	// Remove file paths and line numbers (e.g., "file.yaml:123:45")
	lineNumPattern := regexp.MustCompile(`:[0-9]+:[0-9]+`)
	normalized = lineNumPattern.ReplaceAllString(normalized, ":*:*")

	// Remove just line numbers (e.g., "line 123")
	linePattern := regexp.MustCompile(`line [0-9]+`)
	normalized = linePattern.ReplaceAllString(normalized, "line *")

	// Remove hexadecimal IDs and hashes
	hexPattern := regexp.MustCompile(`[0-9a-f]{8,}`)
	normalized = hexPattern.ReplaceAllString(normalized, "*")

	// Remove quoted strings with dynamic content (keep the pattern but not the content)
	// This catches things like "some dynamic value" -> "*"
	quotedPattern := regexp.MustCompile(`"[^"]*"`)
	normalized = quotedPattern.ReplaceAllString(normalized, `"*"`)

	// Remove single-quoted strings
	singleQuotedPattern := regexp.MustCompile(`'[^']*'`)
	normalized = singleQuotedPattern.ReplaceAllString(normalized, `'*'`)

	// Generate a hash of the normalized reason for efficient storage
	hash := sha256.Sum256([]byte(normalized))
	return fmt.Sprintf("%x", hash)
}

// GetUniqueCount returns the number of unique crashes seen
func (d *Deduplicator) GetUniqueCount() int {
	return len(d.seen)
}
