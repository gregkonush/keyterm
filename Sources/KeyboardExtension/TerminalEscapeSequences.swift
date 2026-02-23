import Foundation

enum TerminalEscapeSequences {
    enum CursorMode {
        case normal
        case application
    }

    enum CursorKey {
        case up
        case down
        case left
        case right
        case home
        case end
    }

    struct Modifiers: OptionSet {
        let rawValue: Int

        static let alt = Modifiers(rawValue: 1 << 0)
        static let control = Modifiers(rawValue: 1 << 1)
    }

    static func cursorKey(
        _ key: CursorKey,
        mode: CursorMode,
        modifiers: Modifiers = []
    ) -> String {
        let suffix = finalCharacter(for: key)
        if modifiers.isEmpty {
            switch mode {
            case .normal:
                return "\u{001B}[\(suffix)"
            case .application:
                return "\u{001B}O\(suffix)"
            }
        }

        // Xterm-style modified cursor keys use CSI 1;<modifier><final>.
        let modifierParameter = cursorModifierParameter(for: modifiers)
        return "\u{001B}[1;\(modifierParameter)\(suffix)"
    }

    static func readlineNavigation(for key: CursorKey) -> String? {
        switch key {
        case .up:
            return "\u{0010}" // C-p
        case .down:
            return "\u{000E}" // C-n
        case .left:
            return "\u{0002}" // C-b
        case .right:
            return "\u{0006}" // C-f
        case .home:
            return "\u{0001}" // C-a
        case .end:
            return "\u{0005}" // C-e
        }
    }

    private static func finalCharacter(for key: CursorKey) -> String {
        switch key {
        case .up:
            return "A"
        case .down:
            return "B"
        case .right:
            return "C"
        case .left:
            return "D"
        case .home:
            return "H"
        case .end:
            return "F"
        }
    }

    private static func cursorModifierParameter(for modifiers: Modifiers) -> Int {
        let hasAlt = modifiers.contains(.alt)
        let hasControl = modifiers.contains(.control)

        switch (hasAlt, hasControl) {
        case (false, false):
            return 1
        case (true, false):
            return 3
        case (false, true):
            return 5
        case (true, true):
            return 7
        }
    }
}
