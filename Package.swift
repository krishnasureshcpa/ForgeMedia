// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ForgeMedia",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "6.29.0")
    ],
    targets: [
        // ── Domain ─────────────────────────────────────────────
        .target(
            name: "ForgeMediaDomain",
            dependencies: [],
            path: "Sources/ForgeMediaDomain"
        ),
        .testTarget(
            name: "ForgeMediaDomainTests",
            dependencies: ["ForgeMediaDomain"],
            path: "Tests/ForgeMediaDomainTests"
        ),

        // ── Data ───────────────────────────────────────────────
        .target(
            name: "ForgeMediaData",
            dependencies: [
                "ForgeMediaDomain",
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Sources/ForgeMediaData"
        ),
        .testTarget(
            name: "ForgeMediaDataTests",
            dependencies: ["ForgeMediaData"],
            path: "Tests/ForgeMediaDataTests"
        ),

        // ── Media ──────────────────────────────────────────────
        .target(
            name: "ForgeMediaMedia",
            dependencies: ["ForgeMediaDomain", "ForgeMediaDiagnostics"],
            path: "Sources/ForgeMediaMedia"
        ),
        .testTarget(
            name: "ForgeMediaMediaTests",
            dependencies: ["ForgeMediaMedia"],
            path: "Tests/ForgeMediaMediaTests"
        ),

        // ── AI ─────────────────────────────────────────────────
        .target(
            name: "ForgeMediaAI",
            dependencies: ["ForgeMediaDomain"],
            path: "Sources/ForgeMediaAI"
        ),
        .testTarget(
            name: "ForgeMediaAITests",
            dependencies: ["ForgeMediaAI"],
            path: "Tests/ForgeMediaAITests"
        ),

        // ── Diagnostics ────────────────────────────────────────
        .target(
            name: "ForgeMediaDiagnostics",
            dependencies: ["ForgeMediaDomain"],
            path: "Sources/ForgeMediaDiagnostics"
        ),

        // ── UI ─────────────────────────────────────────────────
        .target(
            name: "ForgeMediaUI",
            dependencies: ["ForgeMediaDomain"],
            path: "Sources/ForgeMediaUI"
        ),

        // ── App (executable) ───────────────────────────────────
        .executableTarget(
            name: "ForgeMediaApp",
            dependencies: [
                "ForgeMediaDomain",
                "ForgeMediaData",
                "ForgeMediaMedia",
                "ForgeMediaAI",
                "ForgeMediaUI",
                "ForgeMediaDiagnostics",
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Sources/ForgeMediaApp"
        ),

        // ── CLI ────────────────────────────────────────────────
        .executableTarget(
            name: "ForgeMediaCLI",
            dependencies: [
                "ForgeMediaDomain",
                "ForgeMediaMedia",
                "ForgeMediaDiagnostics"
            ],
            path: "Sources/ForgeMediaCLI"
        )
    ]
)
