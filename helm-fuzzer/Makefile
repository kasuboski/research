.PHONY: build test lint fmt clean install

# Build the binary
build:
	go build -o helm-fuzz main.go

# Run tests
test:
	go test -v ./...

# Run tests with race detector
test-race:
	go test -race -v ./...

# Run linting
lint:
	go vet ./...
	gofmt -s -l .

# Format code
fmt:
	gofmt -s -w .
	go fmt ./...

# Clean build artifacts
clean:
	rm -f helm-fuzz
	rm -f fuzzer-repro-*.yaml

# Install as standalone binary
install:
	go install

# Run fuzzer on test chart
test-fuzz:
	go run main.go fuzz testdata/buggy-chart --iterations 100

# Build for multiple platforms
build-all:
	GOOS=linux GOARCH=amd64 go build -o dist/helm-fuzz-linux-amd64 main.go
	GOOS=darwin GOARCH=amd64 go build -o dist/helm-fuzz-darwin-amd64 main.go
	GOOS=darwin GOARCH=arm64 go build -o dist/helm-fuzz-darwin-arm64 main.go
	GOOS=windows GOARCH=amd64 go build -o dist/helm-fuzz-windows-amd64.exe main.go
