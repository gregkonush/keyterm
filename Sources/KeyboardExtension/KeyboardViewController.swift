import UIKit

final class KeyboardViewController: UIInputViewController {
    fileprivate enum KeyAction {
        case text(String)
        case escape
        case tab
        case arrowUp
        case arrowDown
        case arrowLeft
        case arrowRight
        case backspace
        case enter
        case space
        case toggleControl
        case nextKeyboard
    }

    private var actionByButtonTag: [Int: KeyAction] = [:]
    private var nextTag = 0
    private weak var controlKeyButton: UIButton?
    private weak var globeButton: UIButton?
    private var isControlEnabled = false

    override func viewDidLoad() {
        super.viewDidLoad()
        buildKeyboard()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        globeButton?.isHidden = !needsInputModeSwitchKey
    }
}

private extension KeyboardViewController {
    func buildKeyboard() {
        let root = UIStackView()
        root.axis = .vertical
        root.distribution = .fillEqually
        root.spacing = 8
        root.translatesAutoresizingMaskIntoConstraints = false

        view.backgroundColor = UIColor(red: 0.1, green: 0.11, blue: 0.16, alpha: 1)
        view.addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            root.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            root.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            view.heightAnchor.constraint(greaterThanOrEqualToConstant: 260)
        ])

        let rows: [[(String, KeyAction)]] = [
            [("Esc", .escape), ("Ctrl", .toggleControl), ("Tab", .tab), ("↑", .arrowUp), ("↓", .arrowDown), ("←", .arrowLeft), ("→", .arrowRight)],
            [("q", .text("q")), ("w", .text("w")), ("e", .text("e")), ("r", .text("r")), ("t", .text("t")), ("y", .text("y")), ("u", .text("u")), ("i", .text("i")), ("o", .text("o")), ("p", .text("p"))],
            [("a", .text("a")), ("s", .text("s")), ("d", .text("d")), ("f", .text("f")), ("g", .text("g")), ("h", .text("h")), ("j", .text("j")), ("k", .text("k")), ("l", .text("l")), ("⌫", .backspace)],
            [("z", .text("z")), ("x", .text("x")), ("c", .text("c")), ("v", .text("v")), ("b", .text("b")), ("n", .text("n")), ("m", .text("m")), ("-", .text("-")), ("/", .text("/")), ("↵", .enter)],
            [("🌐", .nextKeyboard), ("[", .text("[")), ("]", .text("]")), ("{", .text("{")), ("}", .text("}")), (" ", .space), (".", .text(".")), (":", .text(":")), (";", .text(";")), ("\"", .text("\""))]
        ]

        for rowSpec in rows {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 6
            row.distribution = .fillEqually
            row.alignment = .fill

            for (title, action) in rowSpec {
                let button = makeKeyButton(title: title, action: action)
                if case .toggleControl = action {
                    controlKeyButton = button
                }
                if case .nextKeyboard = action {
                    globeButton = button
                }
                row.addArrangedSubview(button)
            }

            root.addArrangedSubview(row)
        }
    }

    func makeKeyButton(title: String, action: KeyAction) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.monospacedSystemFont(ofSize: 20, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.17, green: 0.18, blue: 0.25, alpha: 1)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8

        let tag = nextTag
        nextTag += 1
        actionByButtonTag[tag] = action
        button.tag = tag
        button.addTarget(self, action: #selector(onKeyTap(_:)), for: .touchUpInside)
        return button
    }

    @objc
    func onKeyTap(_ sender: UIButton) {
        guard let action = actionByButtonTag[sender.tag] else {
            return
        }
        apply(action: action)
    }

    func apply(action: KeyAction) {
        switch action {
        case .text(let value):
            insertText(value)
        case .escape:
            textDocumentProxy.insertText("\u{001B}")
        case .tab:
            textDocumentProxy.insertText("\t")
        case .arrowUp:
            textDocumentProxy.insertText("\u{001B}[A")
        case .arrowDown:
            textDocumentProxy.insertText("\u{001B}[B")
        case .arrowLeft:
            textDocumentProxy.insertText("\u{001B}[D")
        case .arrowRight:
            textDocumentProxy.insertText("\u{001B}[C")
        case .backspace:
            textDocumentProxy.deleteBackward()
        case .enter:
            textDocumentProxy.insertText("\n")
        case .space:
            insertText(" ")
        case .toggleControl:
            isControlEnabled.toggle()
            updateControlKeyAppearance()
        case .nextKeyboard:
            advanceToNextInputMode()
        }
    }

    func insertText(_ value: String) {
        guard isControlEnabled else {
            textDocumentProxy.insertText(value)
            return
        }

        defer {
            isControlEnabled = false
            updateControlKeyAppearance()
        }

        guard value.count == 1, let scalar = value.unicodeScalars.first, scalar.isASCII else {
            textDocumentProxy.insertText(value)
            return
        }

        let ascii = UInt8(scalar.value)
        let controlValue = ascii & 0x1F
        if let controlScalar = UnicodeScalar(Int(controlValue)) {
            textDocumentProxy.insertText(String(controlScalar))
        } else {
            textDocumentProxy.insertText(value)
        }
    }

    func updateControlKeyAppearance() {
        let activeColor = UIColor(red: 0.95, green: 0.62, blue: 0.18, alpha: 1)
        let inactiveColor = UIColor(red: 0.17, green: 0.18, blue: 0.25, alpha: 1)
        controlKeyButton?.backgroundColor = isControlEnabled ? activeColor : inactiveColor
    }
}
