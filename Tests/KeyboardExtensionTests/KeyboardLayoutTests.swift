import UIKit
import XCTest

final class KeyboardLayoutTests: XCTestCase {
    func testKeyboardSpacingMatchesTunedLayout() {
        let sut = KeyboardViewController()
        sut.loadViewIfNeeded()

        guard let rootStack = sut.view.subviews.compactMap({ $0 as? UIStackView }).first else {
            XCTFail("Expected a root keyboard stack view")
            return
        }

        XCTAssertEqual(rootStack.spacing, 5)

        guard
            let firstRow = rootStack.arrangedSubviews.first,
            let firstRowStack = firstRow.subviews.compactMap({ $0 as? UIStackView }).first
        else {
            XCTFail("Expected a stack inside first row")
            return
        }

        XCTAssertEqual(firstRowStack.spacing, 5)
    }

    func testKeyboardKeysUseContinuousRoundedCorners() {
        let sut = KeyboardViewController()
        sut.loadViewIfNeeded()

        guard
            let rootStack = sut.view.subviews.compactMap({ $0 as? UIStackView }).first,
            let firstRow = rootStack.arrangedSubviews.first,
            let firstRowStack = firstRow.subviews.compactMap({ $0 as? UIStackView }).first,
            let firstButton = firstRowStack.arrangedSubviews.compactMap({ $0 as? UIButton }).first
        else {
            XCTFail("Expected at least one key button")
            return
        }

        XCTAssertEqual(firstButton.layer.cornerCurve, .continuous)
        XCTAssertEqual(firstButton.layer.cornerRadius, 9)
    }

    func testRowsUseNonRequiredPreferredHeights() {
        let sut = KeyboardViewController()
        sut.loadViewIfNeeded()

        guard let rootStack = sut.view.subviews.compactMap({ $0 as? UIStackView }).first else {
            XCTFail("Expected a root keyboard stack view")
            return
        }

        XCTAssertEqual(rootStack.arrangedSubviews.count, 5, "Expected utility row + 4 layout rows")

        for row in rootStack.arrangedSubviews {
            let rowHeightConstraints = row.constraints.filter { constraint in
                constraint.firstItem as AnyObject === row &&
                    constraint.secondItem == nil &&
                    constraint.firstAttribute == .height &&
                    constraint.relation == .equal
            }

            XCTAssertFalse(rowHeightConstraints.isEmpty, "Expected a preferred height on each row")
            XCTAssertTrue(
                rowHeightConstraints.allSatisfy { $0.priority.rawValue < UILayoutPriority.required.rawValue },
                "Row should not use required fixed height constraints"
            )
        }
    }

    func testRootStackBottomConstraintIsFlexible() {
        let sut = KeyboardViewController()
        sut.loadViewIfNeeded()

        guard let rootStack = sut.view.subviews.compactMap({ $0 as? UIStackView }).first else {
            XCTFail("Expected a root keyboard stack view")
            return
        }

        let bottomConstraints = sut.view.constraints.filter { constraint in
            constraint.firstItem as AnyObject === rootStack &&
                constraint.secondItem as AnyObject === sut.view &&
                constraint.firstAttribute == .bottom &&
                constraint.secondAttribute == .bottom
        }

        XCTAssertEqual(bottomConstraints.count, 1)
        XCTAssertEqual(bottomConstraints.first?.relation, .lessThanOrEqual)
    }
}
