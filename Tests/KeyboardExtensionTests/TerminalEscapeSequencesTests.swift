import XCTest

final class TerminalEscapeSequencesTests: XCTestCase {
    func testNormalCursorSequences() {
        XCTAssertEqual(
            TerminalEscapeSequences.cursorKey(.up, mode: .normal),
            "\u{001B}[A"
        )
        XCTAssertEqual(
            TerminalEscapeSequences.cursorKey(.down, mode: .normal),
            "\u{001B}[B"
        )
        XCTAssertEqual(
            TerminalEscapeSequences.cursorKey(.right, mode: .normal),
            "\u{001B}[C"
        )
        XCTAssertEqual(
            TerminalEscapeSequences.cursorKey(.left, mode: .normal),
            "\u{001B}[D"
        )
    }

    func testApplicationCursorSequences() {
        XCTAssertEqual(
            TerminalEscapeSequences.cursorKey(.up, mode: .application),
            "\u{001B}OA"
        )
        XCTAssertEqual(
            TerminalEscapeSequences.cursorKey(.down, mode: .application),
            "\u{001B}OB"
        )
        XCTAssertEqual(
            TerminalEscapeSequences.cursorKey(.right, mode: .application),
            "\u{001B}OC"
        )
        XCTAssertEqual(
            TerminalEscapeSequences.cursorKey(.left, mode: .application),
            "\u{001B}OD"
        )
    }

    func testHomeAndEndFollowCursorMode() {
        XCTAssertEqual(
            TerminalEscapeSequences.cursorKey(.home, mode: .normal),
            "\u{001B}[H"
        )
        XCTAssertEqual(
            TerminalEscapeSequences.cursorKey(.end, mode: .normal),
            "\u{001B}[F"
        )
        XCTAssertEqual(
            TerminalEscapeSequences.cursorKey(.home, mode: .application),
            "\u{001B}OH"
        )
        XCTAssertEqual(
            TerminalEscapeSequences.cursorKey(.end, mode: .application),
            "\u{001B}OF"
        )
    }

    func testModifiedCursorSequencesUseXtermEncoding() {
        XCTAssertEqual(
            TerminalEscapeSequences.cursorKey(.up, mode: .normal, modifiers: [.alt]),
            "\u{001B}[1;3A"
        )
        XCTAssertEqual(
            TerminalEscapeSequences.cursorKey(.left, mode: .normal, modifiers: [.control]),
            "\u{001B}[1;5D"
        )
        XCTAssertEqual(
            TerminalEscapeSequences.cursorKey(.right, mode: .application, modifiers: [.alt, .control]),
            "\u{001B}[1;7C"
        )
    }

    func testReadlineFallbackSequences() {
        XCTAssertEqual(TerminalEscapeSequences.readlineNavigation(for: .left), "\u{0002}")
        XCTAssertEqual(TerminalEscapeSequences.readlineNavigation(for: .right), "\u{0006}")
        XCTAssertEqual(TerminalEscapeSequences.readlineNavigation(for: .up), "\u{0010}")
        XCTAssertEqual(TerminalEscapeSequences.readlineNavigation(for: .down), "\u{000E}")
        XCTAssertEqual(TerminalEscapeSequences.readlineNavigation(for: .home), "\u{0001}")
        XCTAssertEqual(TerminalEscapeSequences.readlineNavigation(for: .end), "\u{0005}")
    }
}
