import SwiftButler

struct NoteDetail: Codable {
	let message: String
	let location: LocationInfo?
	let sourceLineText: String?

	init(from note: SyntaxNote) {
		self.message = note.message
		if let loc = note.location {
			self.location = LocationInfo(
				line: loc.line,
				column: loc.column,
				offset: loc.offset
			)
		} else {
			self.location = nil
		}
		self.sourceLineText = note.sourceLineText
	}
}
