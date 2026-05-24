// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_native_html_to_pdf",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "flutter-native-html-to-pdf", targets: ["flutter_native_html_to_pdf"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flutter_native_html_to_pdf",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
