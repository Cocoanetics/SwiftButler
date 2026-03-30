struct ErrorSummary: Codable {
	let totalFilesAnalyzed: Int
	let filesWithErrors: Int
	let totalErrors: Int
	let files: [FileErrorReport]
}
