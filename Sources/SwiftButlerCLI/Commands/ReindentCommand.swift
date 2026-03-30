import ArgumentParser
import Foundation
import SwiftButler

struct ReindentCommand: AsyncParsableCommand {
	internal static let defaultSpaceCount = 3

	static let configuration = CommandConfiguration(
		commandName: "reindent",
		abstract: "Fix indentation in Swift source files using spaces or tabs",
		discussion: """
  Reindent Swift source files in place with consistent indentation. This command processes files or directories
  and applies proper indentation with configurable spacing or tabs, including special handling for switch statements
  where case labels are indented deeper than the switch itself.

  Examples:
    butler reindent MyFile.swift                         # Reindent with the default 3-space indentation
    butler reindent MyFile.swift --spaces 2             # Use 2-space indentation
    butler reindent MyFile.swift --tabs                 # Use tab indentation
    butler reindent Sources/ --recursive                # Reindent all Swift files in Sources recursively
    butler reindent file1.swift file2.swift --dry-run   # Show what would be changed without modifying files
"""
	)

	@Argument(help: "Swift file(s) or directory to reindent")
	var paths: [String]

	@Flag(name: .shortAndLong, help: "Recursively search directories for Swift files")
	var recursive: Bool = false

	@Option(name: .long, help: "Number of spaces per indentation level")
	var spaces: Int?

	@Flag(name: .long, help: "Use tabs for indentation")
	var tabs: Bool = false

	@Flag(help: "Show what would be changed without modifying files")
	var dryRun: Bool = false

	mutating func validate() throws {
		if tabs && spaces != nil {
			throw ValidationError("Use either --tabs or --spaces <n>, not both.")
		}

		if let spaces, !(1...16).contains(spaces) {
			throw ValidationError("Invalid space count: \(spaces). Must be between 1 and 16.")
		}
	}

	func run() async throws {
		print("🔧 SwiftButler Indentation Fixer")
		print("=========================\n")

		let indentationStyle: IndentationStyle = tabs ? .tabs : .spaces(spaces ?? Self.defaultSpaceCount)
		let indentationDescription = tabs ? "tab indentation" : "\(spaces ?? Self.defaultSpaceCount)-space indentation"

		let swiftFiles = try collectSwiftFiles(from: paths, recursive: recursive)

		if swiftFiles.isEmpty {
			print("❌ No Swift files found in the specified paths.")
			throw ExitCode.failure
		}

		print("📁 Found \(swiftFiles.count) Swift file(s) to reindent...")
		print("🔧 Using \(indentationDescription)")

		if dryRun {
			print("🔍 Dry run mode - no files will be modified\n")
		} else {
			print("⚠️  Files will be modified in place\n")
		}

		var filesModified = 0
		var totalFiles = 0

		for filePath in swiftFiles {
			totalFiles += 1
			let url = URL(fileURLWithPath: filePath)

			do {
				let originalContent = try String(contentsOf: url)
				let tree = try SyntaxTree(string: originalContent)
				let reindentedTree = try tree.reindent(using: indentationStyle)
				let newContent = reindentedTree.serializeToCode()

				if originalContent != newContent {
					filesModified += 1

					if dryRun {
						print("📝 \(filePath): Would be modified")
						let originalLines = originalContent.components(separatedBy: .newlines).count
						let newLines = newContent.components(separatedBy: .newlines).count
						print("   Lines: \(originalLines) → \(newLines)")
					} else {
						try newContent.write(to: url, atomically: true, encoding: .utf8)
						print("✅ \(filePath): Reindented")
					}
				} else {
					print("⏭️  \(filePath): Already properly indented")
				}
			} catch {
				print("❌ \(filePath): Failed to process - \(error)")
			}
		}

		if dryRun {
			print("\n📊 Summary (Dry Run):")
			print("   Files analyzed: \(totalFiles)")
			print("   Files that would be modified: \(filesModified)")
			print("   Files already correct: \(totalFiles - filesModified)")
		} else {
			print("\n📊 Summary:")
			print("   Files processed: \(totalFiles)")
			print("   Files modified: \(filesModified)")
			print("   Files already correct: \(totalFiles - filesModified)")
		}

		if filesModified > 0 {
			if dryRun {
				print("\n🔍 Run without --dry-run to apply these changes.")
			} else {
				print("\n✅ Indentation fixing complete!")
			}
		} else {
			print("\n✅ All files already have correct indentation!")
		}
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
						for file in contents where file.hasSuffix(".swift") {
							swiftFiles.append(URL(fileURLWithPath: path).appendingPathComponent(file).path)
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
