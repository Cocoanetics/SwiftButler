import ArgumentParser
import SwiftButler

extension VisibilityLevel: ExpressibleByArgument {}

@main
struct SwiftButlerCLI: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "butler",
		abstract: "Swift source tooling for analysis, syntax checking, and refactoring",
		version: swiftButlerVersion,
		subcommands: [AnalyzeCommand.self, SyntaxCheckCommand.self, DistributeCommand.self, ReindentCommand.self],
		defaultSubcommand: AnalyzeCommand.self
	)
}
