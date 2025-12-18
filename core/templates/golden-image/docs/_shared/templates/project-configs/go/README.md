# Go Configuration Templates

## Overview

Configuration templates for Go projects, covering module management and linting.

## Detection

**Marker Files:**
- `go.mod` → Go module

**Load When:** `go.mod` exists

## Template Hierarchy

```
go/
├── README.md             # This file
├── gomod.template        # Go module configuration
└── golangci.template     # golangci-lint configuration
```

## Quick Reference

| Config | Purpose | Required When |
|--------|---------|---------------|
| `go.mod` | Module definition, dependencies | Any Go project |
| `.golangci.yml` | Linting configuration | Any Go project |

## Go Toolchain

Go has excellent built-in tooling:

| Tool | Purpose | Built-in |
|------|---------|----------|
| `go build` | Compile | ✅ |
| `go test` | Testing | ✅ |
| `go fmt` | Formatting | ✅ |
| `go vet` | Static analysis | ✅ |
| `golangci-lint` | Comprehensive linting | External |

## Project Structure

### Application
```
myapp/
├── go.mod              # Module definition
├── go.sum              # Dependency checksums
├── main.go             # Entry point
├── cmd/
│   └── myapp/
│       └── main.go     # For multi-command apps
├── internal/           # Private packages
│   └── handler/
├── pkg/                # Public packages (optional)
└── .golangci.yml       # Linter config
```

### Library
```
mylibrary/
├── go.mod
├── go.sum
├── mylibrary.go        # Main package
├── mylibrary_test.go   # Tests
├── internal/           # Private implementation
└── .golangci.yml
```

## Config Loading Order

1. **Always exists:** `go.mod` (required for Go modules)
2. **Always add:** `.golangci.yml` for linting
3. **Optional:** `Makefile` for task automation

## Integration Points

### go.mod + go.sum

`go.sum` is auto-generated. Don't edit it manually.

```bash
# Update dependencies
go get -u ./...

# Tidy (remove unused, add missing)
go mod tidy

# Verify checksums
go mod verify
```

### golangci-lint + go vet

golangci-lint includes `go vet` by default. No separate configuration needed.

## Common Commands

```bash
# Format all files
go fmt ./...

# Vet for common mistakes
go vet ./...

# Run tests
go test ./...

# Run tests with coverage
go test -cover ./...

# Build
go build ./...

# Build specific binary
go build -o bin/myapp ./cmd/myapp

# Run linter
golangci-lint run

# List dependencies
go list -m all
```

## When NOT to Use These Templates

| Scenario | Skip These |
|----------|------------|
| Python project | All Go configs |
| JavaScript project | All Go configs |
| Non-Go tooling | All Go configs |

## Environment Variables

```bash
# Common Go environment
export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOBIN

# Module proxy (default works fine)
# export GOPROXY=https://proxy.golang.org,direct

# Private modules
# export GOPRIVATE=github.com/myorg/*
```

## Version Notes

- **Go 1.21+**: Recommended minimum
- **Go modules**: Now standard (GOPATH mode deprecated)
- **Generics**: Available since Go 1.18
