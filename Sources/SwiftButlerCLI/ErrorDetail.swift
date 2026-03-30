import SwiftButler

struct ErrorDetail: Codable {
	let message: String
	let location: LocationInfo
	let sourceLineText: String
	let caretLineText: String
	let contextRange: String
	let sourceContext: [String]
	let fixIts: [FixItDetail]
	let notes: [NoteDetail]

	init(from syntaxError: SyntaxErrorDetail) {
		self.message = syntaxError.message
		self.location = LocationInfo(
			line: syntaxError.location.line,
			column: syntaxError.location.column,
			offset: syntaxError.location.offset
		)
		self.sourceLineText = syntaxError.sourceLineText
		self.caretLineText = syntaxError.caretLineText
		self.contextRange = syntaxError.contextRange
		self.sourceContext = syntaxError.sourceContext
		self.fixIts = syntaxError.fixIts.map { FixItDetail(from: $0) }
		self.notes = syntaxError.notes.map { NoteDetail(from: $0) }
	}
}
