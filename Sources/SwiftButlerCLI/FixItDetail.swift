import SwiftButler

struct FixItDetail: Codable {
	let message: String
	let originalText: String
	let replacementText: String
	let location: LocationInfo

	init(from fixIt: SyntaxFixIt) {
		self.message = fixIt.message
		self.originalText = fixIt.originalText
		self.replacementText = fixIt.replacementText
		self.location = LocationInfo(
			line: fixIt.range.line,
			column: fixIt.range.column,
			offset: fixIt.range.offset
		)
	}
}
