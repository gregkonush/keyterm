import XCTest

final class KeyboardHapticFeedbackTests: XCTestCase {
    func testPrepareAndEmitDoNotCrash() {
        let sut = KeyboardHapticFeedback()
        sut.prepare()
        sut.emitKeyTap()
    }
}
