import ArgumentParser

enum ErrorOutputFormat: String, CaseIterable, ExpressibleByArgument {
	case json
	case markdown

	var defaultValueDescription: String {
		switch self {
		case .json:
			"JSON format"
		case .markdown:
			"Markdown format"
		}
	}
}
