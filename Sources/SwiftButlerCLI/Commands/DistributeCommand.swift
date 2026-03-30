import ArgumentParser
import Foundation
import SwiftButler

struct DistributeCommand: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "distribute",
		abstract: "Split Swift files into separate files for each top-level declaration, preserving imports.",
		discussion: """
  For each input file, splits all top-level declarations into separate files (e.g., Type.swift, Type+Protocol.swift), preserving import statements.
  If a directory is given, all .swift files are processed (recursively if -r is set).
  By default, writes to an output directory (or prints to stdout if not specified).

  Examples:
    butler distribute MyFile.swift
    butler distribute Sources/ --recursive -o SplitSources
    butler distribute file1.swift file2.swift -o out
"""
	)

	@Argument(help: "Swift file(s) or directory to split")
	var paths: [String]

	@Flag(name: .shortAndLong, help: "Recursively search directories for Swift files")
	var recursive: Bool = false

	@Option(name: .shortAndLong, help: "Output directory (default: print to stdout)")
	var output: String?

	@Flag(name: .long, help: "Show what would be written, but do not write any files")
	var dryRun: Bool = false

	func run() async throws {
		let swiftFiles = try collectSwiftFiles(from: paths, recursive: recursive)
		guard !swiftFiles.isEmpty else {
			print("❌ No Swift files found in the specified paths.")
			throw ExitCode.failure
		}

		print("📁 Found \(swiftFiles.count) Swift file(s) to distribute...")
		let outputDir: URL? = output.map { URL(fileURLWithPath: $0) }
		if let dir = outputDir {
			try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
		}

		if dryRun {
			var outputBuffer = ""
			let filesByFolder = Dictionary(grouping: swiftFiles) { filePath in
				URL(fileURLWithPath: filePath).deletingLastPathComponent().path
			}
			for (folder, files) in filesByFolder.sorted(by: { $0.key < $1.key }) {
				outputBuffer += "\n📂 \(folder)\n"
				var outputLines: [(isEdit: Bool, name: String, info: String)] = []
				for filePath in files.sorted() {
					let url = URL(fileURLWithPath: filePath)
					let source = try String(contentsOf: url)
					let tree = try SyntaxTree(string: source)
					let distributor = CodeDistributor()
					let result = try distributor.distributeKeepingFirst(tree: tree, originalFileName: url.lastPathComponent)
					let targetDir: URL = outputDir ?? url.deletingLastPathComponent()
					let originalPath = targetDir.appendingPathComponent(result.modifiedOriginalFile?.fileName ?? "(none)").lastPathComponent
					if let original = result.modifiedOriginalFile {
						let oldLineCount = source.split(separator: "\n").count
						let newLineCount = original.content.split(separator: "\n").count
						outputLines.append((true, originalPath, "[\(oldLineCount)→\(newLineCount)]"))
					}
					for file in result.newFiles {
						let fileName = targetDir.appendingPathComponent(file.fileName).lastPathComponent
						let lineCount = file.content.split(separator: "\n").count
						outputLines.append((false, fileName, "[\(lineCount)]"))
					}
				}
				for (index, line) in outputLines.enumerated() {
					let branch = index == outputLines.count - 1 ? "└─" : "├─"
					let icon = line.isEdit ? "✏️" : "🆕"
					outputBuffer += "  \(branch) \(icon)  \(line.name) \(line.info)\n"
				}
			}
			outputBuffer += "\n✅ Distribution complete.\n"
			print(compressEmptyLines(outputBuffer))
			return
		}

		for filePath in swiftFiles {
			let url = URL(fileURLWithPath: filePath)
			print("\n=== Processing: \(filePath) ===")
			let source = try String(contentsOf: url)
			let tree = try SyntaxTree(string: source)
			let distributor = CodeDistributor()
			let result = try distributor.distributeKeepingFirst(tree: tree, originalFileName: url.lastPathComponent)
			let targetDir: URL = outputDir ?? url.deletingLastPathComponent()

			if let original = result.modifiedOriginalFile {
				let originalPath = url
				let newPath = targetDir.appendingPathComponent(original.fileName)
				let contentWithNewline = ensureEndsWithNewline(original.content)
				try contentWithNewline.write(to: newPath, atomically: true, encoding: .utf8)
				print("  → Wrote \(original.fileName)")
				if originalPath.lastPathComponent != original.fileName {
					try? FileManager.default.removeItem(at: originalPath)
					print("  ⨂ Deleted old file \(originalPath.lastPathComponent)")
				}
			}

			for file in result.newFiles {
				let outPath = targetDir.appendingPathComponent(file.fileName)
				let contentWithNewline = ensureEndsWithNewline(file.content)
				try contentWithNewline.write(to: outPath, atomically: true, encoding: .utf8)
				print("  → Wrote \(file.fileName)")
			}
		}

		print("\n✅ Distribution complete.")
	}

	internal func describeDeclarations(in content: String) -> String {
		let pattern = "^(public |internal |private |fileprivate |open )?(struct|class|enum|extension|protocol|typealias|actor)\\s+([A-Za-z0-9_+]+)"
		let lines = content.split(separator: "\n")
		var declarations: [String] = []
		for line in lines {
			if let match = line.range(of: pattern, options: [.regularExpression, .anchored]) {
				let declaration = String(line[match])
				declarations.append(declaration.trimmingCharacters(in: .whitespaces))
			}
		}
		return declarations.joined(separator: ", ")
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

	internal func compressEmptyLines(_ text: String) -> String {
		let lines = text.components(separatedBy: "\n")
		var result: [String] = []
		var lastWasEmpty = false
		for line in lines {
			if line.trimmingCharacters(in: .whitespaces).isEmpty {
				if !lastWasEmpty {
					result.append("")
					lastWasEmpty = true
				}
			} else {
				result.append(line)
				lastWasEmpty = false
			}
		}
		return result.joined(separator: "\n")
	}

	internal func ensureEndsWithNewline(_ content: String) -> String {
		content.hasSuffix("\n") ? content : content + "\n"
	}

	internal func hasFileConflicts(result: DistributionResult, originalURL: URL, targetDir: URL) -> Bool {
		var conflicts: [String] = []
		let fileManager = FileManager.default

		func pathExists(_ fileName: String) -> Bool {
			fileManager.fileExists(atPath: targetDir.appendingPathComponent(fileName).path)
		}

		if let original = result.modifiedOriginalFile {
			let newName = original.fileName
			if newName != originalURL.lastPathComponent && pathExists(newName) {
				conflicts.append(newName)
			}
		}

		for file in result.newFiles where pathExists(file.fileName) {
			conflicts.append(file.fileName)
		}

		if !conflicts.isEmpty {
			print("⚠️  File conflict(s) detected: \(conflicts.joined(separator: ", "))")
		}
		return !conflicts.isEmpty
	}
}
