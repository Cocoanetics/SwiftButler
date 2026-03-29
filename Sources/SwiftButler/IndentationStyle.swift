import SwiftSyntax

public enum IndentationStyle: Equatable, Sendable {
	case spaces(Int)
	case tabs

	var unitWidth: Int {
		switch self {
			case .spaces(let count):
				return count
			case .tabs:
				return 1
		}
	}

	func triviaPieces(forLevel level: Int) -> [TriviaPiece] {
		guard level > 0 else { return [] }

		switch self {
			case .spaces(let count):
				return [.spaces(level * count)]
			case .tabs:
				return [.tabs(level)]
		}
	}

	func triviaPieces(forColumns column: Int) -> [TriviaPiece] {
		guard column > 0 else { return [] }

		switch self {
			case .spaces:
				return [.spaces(column)]
			case .tabs:
				return [.tabs(column)]
		}
	}
}
