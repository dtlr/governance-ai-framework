# Rust Configuration Templates

## Overview

Configuration templates for Rust projects, covering package management and code formatting.

## Detection

**Marker Files:**
- `Cargo.toml` → Rust project

**Load When:** `Cargo.toml` exists

## Template Hierarchy

```
rust/
├── README.md           # This file
├── cargo.template      # Cargo.toml configuration
└── rustfmt.template    # Code formatting
```

## Quick Reference

| Config | Purpose | Required When |
|--------|---------|---------------|
| `Cargo.toml` | Package manifest | Any Rust project |
| `rustfmt.toml` | Code formatting | Optional (defaults work well) |
| `.clippy.toml` | Linting config | Optional |

## Rust Toolchain

Rust has excellent built-in tooling via Cargo:

| Tool | Purpose | Built-in |
|------|---------|----------|
| `cargo build` | Compile | ✅ |
| `cargo test` | Testing | ✅ |
| `cargo fmt` | Formatting | ✅ |
| `cargo clippy` | Linting | ✅ (rustup component) |
| `cargo doc` | Documentation | ✅ |
| `cargo check` | Fast type checking | ✅ |

## Project Structure

### Binary (Application)
```
myapp/
├── Cargo.toml           # Package manifest
├── Cargo.lock           # Dependency lock (commit this!)
├── src/
│   └── main.rs          # Entry point
├── tests/
│   └── integration.rs   # Integration tests
├── benches/             # Benchmarks
└── rustfmt.toml         # Formatting (optional)
```

### Library
```
mylibrary/
├── Cargo.toml
├── Cargo.lock           # Optional for libraries
├── src/
│   └── lib.rs           # Library root
├── tests/
│   └── integration.rs
└── examples/
    └── basic.rs
```

### Workspace (Multiple Crates)
```
workspace/
├── Cargo.toml           # Workspace manifest
├── Cargo.lock
├── crates/
│   ├── core/
│   │   ├── Cargo.toml
│   │   └── src/
│   └── cli/
│       ├── Cargo.toml
│       └── src/
└── rustfmt.toml         # Shared formatting
```

## Config Loading Order

1. **Always exists:** `Cargo.toml` (required)
2. **Optional:** `rustfmt.toml` (defaults are good)
3. **Optional:** `.clippy.toml` (rarely needed)

## Common Commands

```bash
# Check code (fast, no output)
cargo check

# Build debug
cargo build

# Build release
cargo build --release

# Run
cargo run

# Test
cargo test

# Format
cargo fmt

# Lint
cargo clippy

# Documentation
cargo doc --open

# Update dependencies
cargo update

# Audit security
cargo audit
```

## When NOT to Use These Templates

| Scenario | Skip These |
|----------|------------|
| Non-Rust project | All Rust configs |
| JavaScript project | All Rust configs |
| Go project | All Rust configs |

## Version Management

Use `rustup` for toolchain management:

```bash
# Install specific version
rustup install 1.75.0

# Set default
rustup default stable

# Project-specific version
echo "1.75.0" > rust-toolchain.toml

# Or with components
cat > rust-toolchain.toml << EOF
[toolchain]
channel = "1.75.0"
components = ["rustfmt", "clippy"]
EOF
```

## Dependencies

### Add via CLI
```bash
cargo add serde
cargo add serde --features derive
cargo add tokio --features full
cargo add --dev mockall
```

### Cargo.lock

- **Binaries:** Always commit `Cargo.lock`
- **Libraries:** Traditionally optional, but increasingly recommended to commit

## Integration Notes

### With CI/CD

```yaml
# GitHub Actions
- uses: dtolnay/rust-toolchain@stable
  with:
    components: rustfmt, clippy

- run: cargo fmt --check
- run: cargo clippy -- -D warnings
- run: cargo test
```

### With Pre-commit

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/doublify/pre-commit-rust
    rev: v1.0
    hooks:
      - id: fmt
      - id: cargo-check
```

## Version Notes

- **Rust 2021 Edition:** Current standard
- **MSRV:** Minimum Supported Rust Version, declare in Cargo.toml
- **Clippy:** Lints evolve with Rust versions
