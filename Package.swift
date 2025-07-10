// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BNDocumentScanner",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "BNDocumentScanner", targets: ["BNDocumentScanner"]),
    ],
    targets: [
        .target(name: "BNDocumentScanner"),
    ]
)
