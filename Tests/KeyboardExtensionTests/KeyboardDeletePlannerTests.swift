import XCTest

final class KeyboardDeletePlannerTests: XCTestCase {
    func testBackwardDeleteCountForEmptyContext() {
        XCTAssertEqual(KeyboardDeletePlanner.backwardDeleteCount(in: ""), 0)
    }

    func testBackwardDeleteCountForWordWithoutTrailingWhitespace() {
        XCTAssertEqual(KeyboardDeletePlanner.backwardDeleteCount(in: "keyterm"), 7)
    }

    func testBackwardDeleteCountConsumesTrailingWhitespaceAndWord() {
        XCTAssertEqual(KeyboardDeletePlanner.backwardDeleteCount(in: "git status   "), 9)
    }

    func testBackwardDeleteCountForWhitespaceOnly() {
        XCTAssertEqual(KeyboardDeletePlanner.backwardDeleteCount(in: "   \n"), 4)
    }

    func testBackwardDeleteCountUsesWordBoundaryWithinPathLikeToken() {
        XCTAssertEqual(KeyboardDeletePlanner.backwardDeleteCount(in: "cd /workspace/keyterm"), 7)
    }

    func testBackwardDeleteCountTreatsTerminalPunctuationAsSingleSemanticUnit() {
        XCTAssertEqual(KeyboardDeletePlanner.backwardDeleteCount(in: "echo hello!"), 1)
    }
}
