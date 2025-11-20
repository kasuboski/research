#!/bin/sh
set -e

# Helm plugin installation script
echo "Installing helm-fuzz plugin..."

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case $ARCH in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Build the binary
echo "Building helm-fuzz for $OS/$ARCH..."

if command -v go >/dev/null 2>&1; then
    # Build from source
    cd "$HELM_PLUGIN_DIR"
    go build -o helm-fuzz main.go
    chmod +x helm-fuzz
    echo "✅ helm-fuzz installed successfully!"
else
    echo "❌ Go is not installed. Please install Go 1.22+ to build the plugin."
    exit 1
fi
