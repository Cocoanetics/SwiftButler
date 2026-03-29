---
name: swiftbutler
version: 1.0.0
description: >
  Analyze, syntax-check, reindent, and distribute Swift source code with the
  SwiftButler CLI. Use when working with Swift files or packages and you need a
  compact API overview (`analyze` in interface/json/yaml/markdown), fast syntax
  validation (`check`), indentation cleanup with spaces or tabs (`reindent`), or
  to split large Swift files into declaration-based output files (`distribute`).
  Also use when setting up SwiftButler from Homebrew or verifying the installed
  CLI version.
homepage: https://github.com/Cocoanetics/SwiftButler
metadata:
  openclaw:
    emoji: "🧹"
    requires:
      bins: ["butler"]
    install:
      - id: brew
        kind: brew
        formula: cocoanetics/tap/swiftbutler
        bins: ["butler"]
        label: "Install SwiftButler via Homebrew"
---

# SwiftButler

Use `butler` to reduce Swift source into a more manageable working surface.

## Setup

Install via Homebrew:

```bash
brew install cocoanetics/tap/swiftbutler
```

Verify:

```bash
butler --version
```

For local development from a checkout:

```bash
swift build
.build/debug/butler --version
```

## Core Rules

- Prefer `analyze` when an agent needs API shape, not full implementation details.
- Prefer `--format yaml` or `--format json` when the result will be parsed or reused.
- Prefer `check` for fast validation loops before `swift build`.
- Use `reindent` to normalize indentation in place; choose exactly one of `--spaces <n>` or `--tabs`.
- Use `distribute` before targeted edits when a generated file has become too large or noisy.

## Fast Command Map

### Analyze Swift APIs
```bash
# Default interface-style output
butler analyze Sources/MyModule

# Public API only
butler analyze Sources/MyModule --visibility public

# Recursive YAML output for tooling
butler analyze Sources --recursive --format yaml

# Write structured output to a file
butler analyze Sources --recursive --format yaml --output api.yaml
```

Supported formats:
- `interface`
- `json`
- `yaml`
- `markdown`

### Syntax-check Swift quickly
```bash
butler check Sources --recursive
butler check Sources --recursive --json
butler check Sources --recursive --json --pretty
butler check Sources --recursive --format markdown --show-fixits
```

### Reindent with spaces or tabs
```bash
# Default: 3 spaces
butler reindent Sources --recursive

# Explicit spaces
butler reindent Sources --recursive --spaces 2
butler reindent Sources --recursive --spaces 4

# Tabs instead of spaces
butler reindent Sources --recursive --tabs

# Preview without modifying files
butler reindent Sources --recursive --tabs --dry-run
```

Notes:
- `--spaces <n>` accepts values from `1` to `16`.
- `--tabs` and `--spaces <n>` are mutually exclusive.
- Without `--tabs`, the default is `--spaces 3`.

### Distribute large files into smaller ones
```bash
# Split one large generated file
butler distribute Generated.swift

# Preview recursive distribution
butler distribute Sources/Generated --recursive --dry-run

# Write distributed files to a separate directory
butler distribute Sources/Generated --recursive --output SplitSources
```

## When to Use Which Command

- Use `analyze` to hand an LLM a compact view of types, functions, properties, and docs.
- Use `check` inside generation or repair loops for immediate syntax feedback.
- Use `reindent` after generated or patched code has inconsistent indentation.
- Use `distribute` when one large Swift file should become declaration-sized files that are easier to inspect and edit.
