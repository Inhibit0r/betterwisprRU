import Foundation
import Metal
import Testing

/// Fork: the orb export compiles its shader at runtime and crashes the app on failure, so a bad import must fail here instead.
@Test(.enabled(if: MTLCreateSystemDefaultDevice() != nil, "needs a Metal device"))
func liquidOrbShaderCompiles() throws {
    let export = URL(filePath: #filePath).deletingLastPathComponent()
        .appending(path: "../../Sources/LiquidOrb/LiquidOrb.swift").standardized
    let swift = try String(contentsOf: export, encoding: .utf8)
    let start = try #require(swift.range(of: "#\"\"\"\n"))
    let end = try #require(swift.range(of: "\n\"\"\"#", range: start.upperBound..<swift.endIndex))
    let device = try #require(MTLCreateSystemDefaultDevice())
    let library = try device.makeLibrary(source: String(swift[start.upperBound..<end.lowerBound]), options: nil)
    for name in ["vs_main", "fs_main", "ribbon_vs_main", "ribbon_fs_main", "ribbon_composite_fs_main"] {
        #expect(library.makeFunction(name: name) != nil, "\(name) is missing")
    }
}
