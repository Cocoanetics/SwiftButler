# SwiftButler

SwiftButler uses SwiftSyntax to parse Swift code into syntax trees and turn large, noisy Swift codebases into smaller, more useful working surfaces for humans and coding agents.

It is built around three practical jobs:

- `analyze`: produce a bare-bones "header" representation so an LLM can know the API without reading full implementations
- `check`: run lightning-fast syntax checking with precise locations and fix-its
- `distribute`: split large generated files into one file per declaration, including separate protocol conformance extensions, so agents have less code to scan

Detailed CLI usage lives in [CLI.md](/Users/oliver/Developer/SAAE/CLI.md).

## Why SwiftButler

Agentic workflows break down when the working set is too large, too noisy, or too slow to validate.

SwiftButler is useful because it cuts directly into those failure modes:

- Better context density: agents can read compact API surfaces instead of thousands of lines of implementation detail
- Lower token cost: interface-style output is often dramatically smaller than full source
- Faster iteration loops: syntax checking is fast enough to sit directly in generation and repair loops
- Easier file targeting: distributed output makes it more obvious where a change belongs
- Better generated-code hygiene: large synthesized Swift files can be split into maintainable units before an agent starts editing them

In practice, that means less time spent re-reading irrelevant code, fewer blind edits, and faster recoveries when generated output is malformed.

## Why This Matters for LLMs

The problem with feeding raw source trees to an LLM is not just token count. It is signal quality.

Most of the time, an agent does not need every private helper, every implementation branch, or every generated conformance body. It needs to know:

- what types exist
- what the visible API looks like
- where syntax is broken
- how code should be split into smaller working units

SwiftButler is designed around exactly that.

### Benefits in Agentic Workflows

- `analyze` gives agents a compact representation of the public or internal API surface
- `check` gives agents fast, machine-usable feedback after every generation step
- `distribute` reduces oversized files into manageable slices so the next edit is more local and less error-prone

This combination is especially effective in workflows where an agent is:

- learning an unfamiliar codebase
- repairing generated Swift
- refactoring monolithic generated files
- iterating on framework APIs
- validating code before handing off to `swift build` or CI

## Quick Start

```bash
# Clone the repository
git clone https://github.com/Cocoanetics/SwiftButler.git
cd SwiftButler

# Analyze a file
swift run butler path/to/File.swift

# Analyze a directory recursively
swift run butler Sources/ --recursive --format interface --visibility public

# Syntax-check a project
swift run butler check Sources/ --recursive

# Emit JSON for tooling or automation
swift run butler check Sources/ --recursive --json
```

## One Command to Feed an LLM

If you want to hand a framework surface to an agent without drowning it in implementation details:

```bash
swift run butler Sources -v public -r | pbcopy
```

That gives you a compact, interface-style view you can paste directly into a prompt.

## Interface Output

SwiftButler transforms implementation-heavy Swift into a cleaner declaration-oriented view.

Example:

```swift
import Foundation

/// A utility class for mathematical operations
@MainActor
public final class MathUtils {
    /// The mathematical constant pi
    public static var pi: Double { get }

    /**
     Calculates the area of a circle
     
     - Parameter radius: The radius of the circle
     - Returns: The area of the circle
     */
    public static func circleArea(radius: Double) -> Double
}
```

For an agent, that is usually the useful part. The internal implementation can stay out of context until it is actually needed.

## Core Commands

### `analyze`

Use `analyze` when an agent needs to understand the API shape of a file or module.

Typical uses:

- preparing prompt context for an unfamiliar framework
- extracting public interfaces for review
- generating compact architectural summaries

Examples:

```bash
swift run butler MyFile.swift --format interface
swift run butler Sources/MyFramework/ --format markdown --visibility public
swift run butler Sources/ --recursive --format json
```

### `check`

Use `check` inside generation, repair, and validation loops.

Typical uses:

- validating generated Swift before committing it to a larger flow
- returning structured JSON diagnostics to an agent
- rendering markdown reports with fix-its for humans

Examples:

```bash
swift run butler check MyFile.swift
swift run butler check Sources/ --recursive --json
swift run butler check Sources/ --recursive --format markdown --show-fixits
```

Why it helps:

- fast feedback without waiting for a full semantic build
- precise line and column locations
- fix-it suggestions that are useful in automated repair loops

### `distribute`

Use `distribute` when large generated files become too heavy for reliable agent editing.

Typical uses:

- splitting generated model files into one declaration per file
- separating protocol conformances into extension files
- reducing context size before a refactor or targeted edit

Examples:

```bash
swift run butler distribute Generated.swift
swift run butler distribute Sources/Generated --recursive --dry-run
swift run butler distribute Sources/Generated --recursive --output SplitSources
```

Why it helps:

- smaller files are easier for agents to inspect correctly
- conformance extensions become easier to target and reason about
- code ownership becomes more obvious after generation

## Library Use

SwiftButler can also be used directly as a Swift package dependency.

```swift
import SwiftButler

let tree = try SyntaxTree(url: URL(fileURLWithPath: "MyFile.swift"))
let overview = CodeOverview(tree: tree, minVisibility: .public)

let interface = overview.interface()
let json = try overview.json()
let markdown = overview.markdown()
```

You can also parse directly from strings:

```swift
import SwiftButler

let tree = try SyntaxTree(string: swiftCode)
let overview = CodeOverview(tree: tree, minVisibility: .internal)
let interface = overview.interface()
```

## Error Detection

`check` is designed for the part of the loop that comes before compilation.

It catches malformed Swift syntax such as:

- broken type annotations
- invalid declarations
- malformed parameter lists
- operator and expression errors
- missing braces, delimiters, or required tokens

It is especially useful when an agent is repeatedly generating or rewriting Swift and needs immediate feedback before moving on.

### Example

```swift
func invalidFunc: <T>(value: T) -> T {
    return value
}

var property: Int String = 5

let incomplete = 1 + + 2
```

SwiftButler reports precise source locations and can include fix-its, making it suitable for both human review and automated repair.

## Installation

Add SwiftButler to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Cocoanetics/SwiftButler.git", branch: "main")
]
```

## Summary

SwiftButler is a practical tool for agentic Swift workflows because it does three things well:

- compresses code into the API surface an agent actually needs
- validates generated Swift quickly with actionable diagnostics
- restructures oversized generated files into units an agent can edit more safely

That combination makes SwiftButler useful as both a developer tool and a force multiplier for coding agents.
