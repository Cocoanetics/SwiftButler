// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "SwiftButler",
	platforms: [
		.macOS(.v10_15),
		.iOS(.v13),
		.tvOS(.v13),
		.watchOS(.v6)
	],
	products: [
		.library(
			name: "SwiftButler",
			targets: ["SwiftButler"]),
		.executable(
			name: "butler",
			targets: ["SAAEDemo"]),
	],
	dependencies: [
		.package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
		.package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0")
	],
	targets: [
		.target(
			name: "SwiftButler",
			dependencies: [
				.product(name: "SwiftSyntax", package: "swift-syntax"),
				.product(name: "SwiftParser", package: "swift-syntax"),
				.product(name: "SwiftDiagnostics", package: "swift-syntax"),
				.product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
				"Yams"
			],
			path: "Sources/SAAE"),
		.executableTarget(
			name: "SAAEDemo",
			dependencies: [
				"SwiftButler",
				.product(name: "ArgumentParser", package: "swift-argument-parser")
			]),
		.testTarget(
			name: "SAAETests",
			dependencies: [
				"SwiftButler"
			],
			path: "Tests/SAAETests",
			resources: [
				.copy("Resources")
			])
	]
)
