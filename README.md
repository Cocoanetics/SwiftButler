# SwiftButler

SwiftButler uses SwiftSyntax to parse Swift code into syntax trees to:

- `analyze`: produce a bare-bones "header" representation for LLMs to know the API
- `check`: lightning-fast syntax checking with fix-its
- `distribute`: split large generated files into one file per declaration, including separate protocol conformance extensions, to reduce the amount of code agents need to read

CLI usage and command examples live in [CLI.md](/Users/oliver/Developer/SAAE/CLI.md).
