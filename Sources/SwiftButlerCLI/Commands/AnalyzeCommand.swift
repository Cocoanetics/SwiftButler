import ArgumentParser
import Foundation
import SwiftButler

struct AnalyzeCommand: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "analyze",
		abstract: "Generate API overviews from Swift source code",
		discussion: """
  Parse Swift source code and generate clean, structured overviews of your API declarations.
  Perfect for efficiently providing LLMs with comprehensive API overviews instead of overwhelming them with entire codebases.

  Examples:
    butler analyze Sources/SwiftButler
    butler analyze Sources/SwiftButler/*.swift -f json
    butler analyze Sources/SwiftButler --format markdown
    butler analyze Sources/SwiftButler                          # Files in Sources/SwiftButler only
    butler analyze Sources -r -f yaml                    # All files in Sources and subdirectories
    butler analyze Sources/SwiftButler -v public -f interface   # Only public and open declarations
    butler analyze Sources/SwiftButler --visibility private     # All declarations including private
    butler analyze file1.swift file2.swift -f yaml
"""
	)

	@Argument(help: "Swift file(s) or directory to analyze")
	var paths: [String]

	@Option(name: .shortAndLong, help: "Output format")
	var format: OutputFormat = .interface

	@Flag(name: .shortAndLong, help: "Recursively search directories for Swift files")
	var recursive: Bool = false

	@Option(name: .shortAndLong, help: "Minimum visibility level to include")
	var visibility: VisibilityLevel = .internal

	@Option(name: .shortAndLong, help: "Output file path (optional, prints to stdout if not specified)")
	var output: String?

	func run() async throws {
		let analyzer = SwiftButlerAnalyzer(
			paths: paths,
			format: format,
			visibility: visibility,
			recursive: recursive
		)

		let result = try await analyzer.analyze()

		if let outputPath = output {
			try result.write(to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)
			print("✅ Output written to: \(outputPath)")
		} else {
			print(result)
		}
	}
}
