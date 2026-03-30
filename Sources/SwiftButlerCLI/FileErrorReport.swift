struct FileErrorReport: Codable {
	let filePath: String
	let fileName: String
	let errorCount: Int
	let errors: [ErrorDetail]
	let analysisError: String?

	init(filePath: String, fileName: String, errorCount: Int, errors: [ErrorDetail], analysisError: String? = nil) {
		self.filePath = filePath
		self.fileName = fileName
		self.errorCount = errorCount
		self.errors = errors
		self.analysisError = analysisError
	}
}
