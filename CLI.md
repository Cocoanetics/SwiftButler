# SwiftButler CLI

## Commands

### `butler analyze`

Generate API overviews from Swift source files or directories.

```bash
swift run butler MyFile.swift --format interface
swift run butler Sources/MyFramework/ --format interface --visibility public
swift run butler Sources -v public -r | pbcopy
```

Options:

- `--format <interface|json|yaml|markdown>`
- `--visibility <public|internal|private|fileprivate|package|open>`
- `--recursive`
- `--output <path>`

### `butler check`

Syntax-check one or more files or directories. Returns a nonzero exit code when syntax errors are found.

```bash
swift run butler check MyFile.swift
swift run butler check Sources/ --recursive
swift run butler check Sources/ --recursive --json
swift run butler check Sources/ --recursive --json --pretty
swift run butler check Sources/ --recursive --format markdown --show-fixits
```

Options:

- `--recursive`
- `--output <path>`
- `--format <json|markdown>`
- `--json`
- `--pretty`
- `--show-fixits`

### `butler distribute`

Split top-level declarations into separate files, preserving imports.

```bash
swift run butler distribute MyFile.swift
swift run butler distribute Sources/ --recursive --dry-run
swift run butler distribute Sources/ --recursive --output SplitSources
```

Options:

- `--recursive`
- `--output <dir>`
- `--dry-run`

### `butler reindent`

Reindent Swift files in place.

```bash
swift run butler reindent MyFile.swift
swift run butler reindent Sources/ --recursive
swift run butler reindent Sources/ --recursive --spaces 2
swift run butler reindent Sources/ --recursive --tabs
swift run butler reindent Sources/ --recursive --dry-run
```

Options:

- `--recursive`
- `--spaces <n>` (defaults to `3` unless `--tabs` is used)
- `--tabs`
- `--dry-run`
