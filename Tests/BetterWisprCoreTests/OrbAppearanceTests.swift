import Testing
@testable import BetterWispr

/// Fork: Settings → Orb must hand the renderer complete seeds with the customization in the right uniforms.
@Test func orbStyleSeedsMatchTheirShaderStyles() {
    let styleIndex = 15
    for (style, shaderStyle) in [(OrbStyle.prismaticField, Float(14)), (.violetField, 14), (.siriWave, 9)] {
        #expect(style.seeds.idle.count == 136 && style.seeds.thinking.count == 136, "\(style)")
        #expect(style.seeds.idle[styleIndex] == shaderStyle && style.seeds.thinking[styleIndex] == shaderStyle, "\(style)")
    }
}

@Test func orbAppearanceAppliesCustomization() {
    let plain = OrbAppearance(style: .siriWave)
    #expect(plain.seeds.thinking == OrbStyle.siriWave.seeds.thinking)

    let custom = OrbAppearance(style: .siriWave, speed: 2, glass: false, colors: ["#FF0000", "", "not a colour"])
    let base = OrbStyle.siriWave.seeds
    #expect(custom.seeds.thinking[3] == base.thinking[3] * 2 && custom.seeds.idle[3] == base.idle[3] * 2)
    #expect(custom.seeds.thinking[19] == 0 && custom.seeds.idle[19] == 0)
    #expect(Array(custom.seeds.thinking[44..<47]) == [1, 0, 0])
    #expect(custom.seeds.idle[44] < 1 && custom.seeds.idle[44] > custom.seeds.idle[45])
    #expect(Array(custom.seeds.thinking[48..<56]) == Array(base.thinking[48..<56]))
    #expect(OrbAppearance.rgb(OrbAppearance.hex(red: 0.2, green: 0.4, blue: 1)) == [Float(51) / 255, Float(102) / 255, 1])
}
