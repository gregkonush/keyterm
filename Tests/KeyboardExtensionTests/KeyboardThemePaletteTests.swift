import UIKit
import XCTest

final class KeyboardThemePaletteTests: XCTestCase {
    func testResolvedInterfaceStylePrefersKeyboardAppearance() {
        XCTAssertEqual(
            KeyboardThemePalette.resolvedInterfaceStyle(
                keyboardAppearance: .dark,
                traitStyle: .light
            ),
            .dark
        )

        XCTAssertEqual(
            KeyboardThemePalette.resolvedInterfaceStyle(
                keyboardAppearance: .light,
                traitStyle: .dark
            ),
            .light
        )
    }

    func testResolvedInterfaceStyleFallsBackToTraitStyle() {
        XCTAssertEqual(
            KeyboardThemePalette.resolvedInterfaceStyle(
                keyboardAppearance: .default,
                traitStyle: .dark
            ),
            .dark
        )

        XCTAssertEqual(
            KeyboardThemePalette.resolvedInterfaceStyle(
                keyboardAppearance: .default,
                traitStyle: .light
            ),
            .light
        )
    }

    func testBackgroundColors() {
        assertColor(
            KeyboardThemePalette.backgroundColor(for: .dark),
            red: 0.18,
            green: 0.19,
            blue: 0.22
        )

        assertColor(
            KeyboardThemePalette.backgroundColor(for: .light),
            red: 0.80,
            green: 0.82,
            blue: 0.86
        )
    }

    func testKeyColorsForLightAndDark() {
        assertColor(
            KeyboardThemePalette.keyColor(for: .character, interfaceStyle: .dark),
            red: 0.35,
            green: 0.36,
            blue: 0.40
        )
        assertColor(
            KeyboardThemePalette.keyColor(for: .utility, interfaceStyle: .dark),
            red: 0.47,
            green: 0.48,
            blue: 0.53
        )
        assertColor(
            KeyboardThemePalette.keyColor(for: .action, interfaceStyle: .dark),
            red: 0.40,
            green: 0.41,
            blue: 0.46
        )

        assertColor(
            KeyboardThemePalette.keyColor(for: .character, interfaceStyle: .light),
            red: 0.96,
            green: 0.97,
            blue: 0.99
        )
        assertColor(
            KeyboardThemePalette.keyColor(for: .utility, interfaceStyle: .light),
            red: 0.84,
            green: 0.86,
            blue: 0.89
        )
        assertColor(
            KeyboardThemePalette.keyColor(for: .action, interfaceStyle: .light),
            red: 0.88,
            green: 0.90,
            blue: 0.93
        )
    }

    func testActiveModifierColors() {
        assertColor(
            KeyboardThemePalette.activeModifierColor(for: .dark),
            red: 0.30,
            green: 0.57,
            blue: 1.0
        )

        assertColor(
            KeyboardThemePalette.activeModifierColor(for: .light),
            red: 0.19,
            green: 0.47,
            blue: 0.95
        )
    }

    private func assertColor(
        _ color: UIColor,
        red expectedRed: CGFloat,
        green expectedGreen: CGFloat,
        blue expectedBlue: CGFloat,
        alpha expectedAlpha: CGFloat = 1.0,
        accuracy: CGFloat = 0.001,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var red = CGFloat.zero
        var green = CGFloat.zero
        var blue = CGFloat.zero
        var alpha = CGFloat.zero

        XCTAssertTrue(
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha),
            "Expected RGB-compatible color",
            file: file,
            line: line
        )

        XCTAssertEqual(red, expectedRed, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(green, expectedGreen, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(blue, expectedBlue, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(alpha, expectedAlpha, accuracy: accuracy, file: file, line: line)
    }
}
