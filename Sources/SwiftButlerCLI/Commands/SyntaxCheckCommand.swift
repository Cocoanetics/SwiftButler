import ArgumentParser
import Foundation
import SwiftButler

struct SyntaxCheckCommand: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "check",
		abstract: "Check one or more Swift files for syntax errors",
		discussion: """
  Analyze Swift source files for syntax errors. This command accepts one or more files or directories,
  and can recurse into directories with --recursive.

  Examples:
    butler check file.swift
    butler check *.swift
    butler check Sources/ --recursive
    butler check Sources/ --recursive --json
    butler check file.swift --json --output errors.json
    butler check file.swift --format markdown --show-fixits
"""
	)

	@Argument(help: "Swift file(s) or directory to check for syntax errors")
	var paths: [String]

	@Flag(name: .shortAndLong, help: "Recursively search directories for Swift files")
	var recursive: Bool = false

	@Option(name: .shortAndLong, help: "Output file path (optional, prints to stdout if not specified)")
	var output: String?

	@Option(name: .shortAndLong, help: "Output format")
	var format: ErrorOutputFormat = .markdown

	@Flag(help: "Emit JSON output")
	var json: Bool = false

	@Flag(help: "Pretty-print JSON output (ignored for markdown)")
	var pretty: Bool = false

	@Flag(help: "Show fix-it suggestions (like swiftc -fixit)")
	var showFixits: Bool = false

	func run() async throws {
		let swiftFiles = try collectSwiftFiles(from: paths, recursive: recursive)
		let selectedFormat: ErrorOutputFormat = json ? .json : format

		if swiftFiles.isEmpty {
			print("❌ No Swift files found in the specified paths.")
			throw ExitCode.failure
		}

		var allErrors: [FileErrorReport] = []
		var totalErrorCount = 0

		for filePath in swiftFiles {
			let url = URL(fileURLWithPath: filePath)

			do {
				let tree = try SyntaxTree(url: url)
				let errors = tree.syntaxErrors

				if !errors.isEmpty {
					let report = FileErrorReport(
						filePath: filePath,
						fileName: url.lastPathComponent,
						errorCount: errors.count,
						errors: errors.map { ErrorDetail(from: $0) }
					)
					allErrors.append(report)
					totalErrorCount += errors.count
				}
			} catch {
				let report = FileErrorReport(
					filePath: filePath,
					fileName: url.lastPathComponent,
					errorCount: 0,
					errors: [],
					analysisError: error.localizedDescription
				)
				allErrors.append(report)
			}
		}

		let summary = ErrorSummary(
			totalFilesAnalyzed: swiftFiles.count,
			filesWithErrors: allErrors.filter { $0.errorCount > 0 }.count,
			totalErrors: totalErrorCount,
			files: allErrors
		)

		let outputContent: String
		switch selectedFormat {
		case .json:
			outputContent = try generateJSONOutput(summary: summary)
		case .markdown:
			outputContent = generateMarkdownReport(summary)
		}

		if let outputPath = output {
			try outputContent.write(to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)
		} else {
			print(outputContent)
		}

		if totalErrorCount > 0 {
			throw ExitCode.failure
		}
	}

	internal func generateJSONOutput(summary: ErrorSummary) throws -> String {
		let encoder = JSONEncoder()
		if pretty {
			encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
		}

		let jsonData = try encoder.encode(summary)
		return String(data: jsonData, encoding: .utf8) ?? ""
	}

	internal func generateMarkdownReport(_ summary: ErrorSummary) -> String {
		var markdown = ""

		let filesWithErrors = summary.files.filter { $0.errorCount > 0 }

		if filesWithErrors.isEmpty {
			markdown += "✅ **No syntax errors found!**\n\n"
			markdown += "All analyzed files are syntactically correct.\n"
			return markdown
		}

		for fileReport in filesWithErrors {
			for error in fileReport.errors {
				let contextLines = error.sourceContext
				let rangeParts = error.contextRange.components(separatedBy: "-")
				let contextStartLine = Int(rangeParts.first ?? "1") ?? 1
				let maxLineNumber = contextStartLine + contextLines.count - 1
				let lineNumberWidth = String(maxLineNumber).count

				let reportedLineIndex = error.location.line - contextStartLine
				let actualErrorLine = error.location.line

				markdown += "\(fileReport.filePath):\(actualErrorLine):\(error.location.column): error: \(error.message)\n"
				for (index, line) in contextLines.enumerated() {
					let lineNumber = contextStartLine + index
					let isErrorLine = index == reportedLineIndex
					let prefix = String(format: "%*d ┃ ", lineNumberWidth, lineNumber)
					markdown += prefix + line + "\n"
					if isErrorLine {
						var pointerLines: [(String, String)] = [("error", error.message)]
						for note in error.notes {
							var noteMessage = note.message
							if let loc = note.location {
								noteMessage += " (line: \(loc.line), column: \(loc.column))"
							}
							pointerLines.append(("note", noteMessage))
						}
						if showFixits, !error.fixIts.isEmpty {
							for fixIt in error.fixIts {
								pointerLines.append(("fix-it", fixIt.message))
							}
						}
						let pointerCount = pointerLines.count
						let errorColumnPosition = max(0, error.location.column - 1)
						let leadingSpaces = String(repeating: " ", count: lineNumberWidth)
						let pipeSpaces = String(repeating: " ", count: errorColumnPosition)
						for (pointerIndex, (kind, message)) in pointerLines.enumerated() {
							let isLast = pointerIndex == pointerCount - 1
							let branch = isLast ? "┗" : "┣"
							let label = switch kind {
							case "error":
								"error: "
							case "note":
								"note: "
							default:
								"fix-it: "
							}
							let pointerLine = leadingSpaces + " ┃ " + pipeSpaces + branch + "━━ " + label + message + "\n"
							markdown += pointerLine
						}
					}
				}
				markdown += "\n"
			}
		}

		return markdown
	}

	internal func collectSwiftFiles(from paths: [String], recursive: Bool) throws -> [String] {
		var swiftFiles: [String] = []

		for path in paths {
			var isDirectory: ObjCBool = false

			if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) {
				if isDirectory.boolValue {
					if recursive {
						let enumerator = FileManager.default.enumerator(atPath: path)
						while let file = enumerator?.nextObject() as? String {
							if file.hasSuffix(".swift") {
								swiftFiles.append(URL(fileURLWithPath: path).appendingPathComponent(file).path)
							}
						}
					} else {
						let contents = try FileManager.default.contentsOfDirectory(atPath: path)
						for file in contents {
							if file.hasSuffix(".swift") {
								swiftFiles.append(URL(fileURLWithPath: path).appendingPathComponent(file).path)
							}
						}
					}
				} else if path.hasSuffix(".swift") {
					swiftFiles.append(path)
				}
			} else {
				print("⚠️  Path not found: \(path)")
			}
		}

		return swiftFiles.sorted()
	}
}
