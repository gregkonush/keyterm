import UIKit

final class KeyboardViewController: UIInputViewController {
    fileprivate enum KeyboardLayer {
        case letters
        case numbers
        case symbols
    }

    fileprivate enum Layout {
        static let outerInset: CGFloat = 6
        static let rowSpacing: CGFloat = 6
        static let keySpacing: CGFloat = 6
        static let minKeyboardHeight: CGFloat = 236
        static let topRowHeight: CGFloat = 28
        static let rowHeight: CGFloat = 42
        static let bottomRowHeight: CGFloat = 46
    }

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
        case toggleAlt
        case toggleFunction
        case toggleShift
        case setLayer(KeyboardLayer)
        case nextKeyboard
        case home
        case end
        case pageUp
        case pageDown
    }

    fileprivate enum KeyStyle {
        case character
        case utility
        case action
    }

    fileprivate struct KeySpec {
        let title: String?
        let symbolName: String?
        let accessibilityLabel: String
        let action: KeyAction
        let width: CGFloat
        let style: KeyStyle

        init(
            title: String,
            accessibilityLabel: String,
            action: KeyAction,
            width: CGFloat,
            style: KeyStyle
        ) {
            self.title = title
            self.symbolName = nil
            self.accessibilityLabel = accessibilityLabel
            self.action = action
            self.width = width
            self.style = style
        }

        init(
            symbolName: String,
            accessibilityLabel: String,
            action: KeyAction,
            width: CGFloat,
            style: KeyStyle
        ) {
            self.title = nil
            self.symbolName = symbolName
            self.accessibilityLabel = accessibilityLabel
            self.action = action
            self.width = width
            self.style = style
        }
    }

    fileprivate struct RowSpec {
        let sideInset: CGFloat
        let minHeight: CGFloat
        let keys: [KeySpec]
    }

    private let rootStack = UIStackView()

    private var actionByButtonTag: [Int: KeyAction] = [:]
    private var keyStyleByTag: [Int: KeyStyle] = [:]
    private var nextTag = 0

    private weak var globeButton: UIButton?
    private weak var shiftButton: UIButton?
    private weak var controlButton: UIButton?
    private weak var altButton: UIButton?
    private weak var fnButton: UIButton?

    private var keyButtons: [UIButton] = []
    private var functionLayerTextButtons: [String: UIButton] = [:]

    private var currentLayer: KeyboardLayer = .letters
    private var isShiftEnabled = false
    private var isControlEnabled = false
    private var isAltEnabled = false
    private var isFunctionEnabled = false

    override func viewDidLoad() {
        super.viewDidLoad()
        configureRootStack()
        renderKeyboard()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateKeyFonts()
        globeButton?.isHidden = !needsInputModeSwitchKey
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        applyTheme()
        globeButton?.isHidden = !needsInputModeSwitchKey
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyTheme()
    }
}

private extension KeyboardViewController {
    func configureRootStack() {
        rootStack.axis = .vertical
        rootStack.spacing = Layout.rowSpacing
        rootStack.alignment = .fill
        rootStack.distribution = .fill
        rootStack.translatesAutoresizingMaskIntoConstraints = false

        applyTheme()
        view.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.outerInset),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.outerInset),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: Layout.outerInset),
            rootStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Layout.outerInset),
            view.heightAnchor.constraint(greaterThanOrEqualToConstant: Layout.minKeyboardHeight)
        ])
    }

    func renderKeyboard() {
        rootStack.arrangedSubviews.forEach {
            rootStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        actionByButtonTag = [:]
        keyStyleByTag = [:]
        nextTag = 0
        keyButtons.removeAll()
        functionLayerTextButtons.removeAll()
        globeButton = nil
        shiftButton = nil
        controlButton = nil
        altButton = nil
        fnButton = nil

        rootStack.addArrangedSubview(makeTopUtilityRow())
        currentRows().forEach { rowSpec in
            rootStack.addArrangedSubview(makeRow(from: rowSpec))
        }

        applyTheme()
        updateModifierKeyAppearance()
        updateShiftKeyAppearance()
        updateFunctionLayerLegends()
        updateKeyFonts()
        globeButton?.isHidden = !needsInputModeSwitchKey
    }

    func makeTopUtilityRow() -> UIView {
        let row = makeStackContainer(minHeight: Layout.topRowHeight)
        let stack = row.subviews.compactMap { $0 as? UIStackView }.first

        let specs: [KeySpec] = [
            KeySpec(title: "Esc", accessibilityLabel: "Escape", action: .escape, width: 1.0, style: .utility),
            KeySpec(title: "Ctrl", accessibilityLabel: "Control", action: .toggleControl, width: 1.0, style: .utility),
            KeySpec(title: "Alt", accessibilityLabel: "Alt", action: .toggleAlt, width: 1.0, style: .utility),
            KeySpec(title: "Tab", accessibilityLabel: "Tab", action: .tab, width: 1.0, style: .utility),
            KeySpec(title: "Fn", accessibilityLabel: "Function", action: .toggleFunction, width: 1.0, style: .utility),
            KeySpec(symbolName: "arrow.left", accessibilityLabel: "Left Arrow", action: .arrowLeft, width: 1.0, style: .utility),
            KeySpec(symbolName: "arrow.down", accessibilityLabel: "Down Arrow", action: .arrowDown, width: 1.0, style: .utility),
            KeySpec(symbolName: "arrow.up", accessibilityLabel: "Up Arrow", action: .arrowUp, width: 1.0, style: .utility),
            KeySpec(symbolName: "arrow.right", accessibilityLabel: "Right Arrow", action: .arrowRight, width: 1.0, style: .utility)
        ]

        applyRow(specs: specs, to: stack)
        return row
    }

    func currentRows() -> [RowSpec] {
        switch currentLayer {
        case .letters:
            return letterRows()
        case .numbers:
            return numberRows()
        case .symbols:
            return symbolRows()
        }
    }

    func letterRows() -> [RowSpec] {
        let first = RowSpec(sideInset: 0, minHeight: Layout.rowHeight, keys: characterKeys("qwertyuiop"))
        let second = RowSpec(sideInset: 16, minHeight: Layout.rowHeight, keys: characterKeys("asdfghjkl"))

        var thirdKeys: [KeySpec] = [
            KeySpec(
                symbolName: isShiftEnabled ? "shift.fill" : "shift",
                accessibilityLabel: "Shift",
                action: .toggleShift,
                width: 1.25,
                style: .utility
            )
        ]
        thirdKeys.append(contentsOf: characterKeys("zxcvbnm"))
        thirdKeys.append(
            KeySpec(
                symbolName: "delete.left",
                accessibilityLabel: "Delete",
                action: .backspace,
                width: 1.25,
                style: .utility
            )
        )

        let third = RowSpec(sideInset: 4, minHeight: Layout.rowHeight, keys: thirdKeys)
        let fourth = RowSpec(sideInset: 0, minHeight: Layout.bottomRowHeight, keys: bottomKeys(modeTitle: "123", modeAction: .setLayer(.numbers)))

        return [first, second, third, fourth]
    }

    func numberRows() -> [RowSpec] {
        let first = RowSpec(sideInset: 0, minHeight: Layout.rowHeight, keys: textKeys(["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]))
        let second = RowSpec(sideInset: 0, minHeight: Layout.rowHeight, keys: textKeys(["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""]))

        var thirdKeys: [KeySpec] = [
            KeySpec(title: "#+=", accessibilityLabel: "Symbols", action: .setLayer(.symbols), width: 1.45, style: .utility)
        ]
        thirdKeys.append(contentsOf: textKeys([".", ",", "?", "!", "'"]))
        thirdKeys.append(
            KeySpec(
                symbolName: "delete.left",
                accessibilityLabel: "Delete",
                action: .backspace,
                width: 1.2,
                style: .utility
            )
        )

        let third = RowSpec(sideInset: 4, minHeight: Layout.rowHeight, keys: thirdKeys)
        let fourth = RowSpec(sideInset: 0, minHeight: Layout.bottomRowHeight, keys: bottomKeys(modeTitle: "ABC", modeAction: .setLayer(.letters)))

        return [first, second, third, fourth]
    }

    func symbolRows() -> [RowSpec] {
        let first = RowSpec(sideInset: 0, minHeight: Layout.rowHeight, keys: textKeys(["[", "]", "{", "}", "#", "%", "^", "*", "+", "="]))
        let second = RowSpec(sideInset: 0, minHeight: Layout.rowHeight, keys: textKeys(["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"]))

        var thirdKeys: [KeySpec] = [
            KeySpec(title: "123", accessibilityLabel: "Numbers", action: .setLayer(.numbers), width: 1.45, style: .utility)
        ]
        thirdKeys.append(contentsOf: textKeys([".", ",", "?", "!", "'"]))
        thirdKeys.append(
            KeySpec(
                symbolName: "delete.left",
                accessibilityLabel: "Delete",
                action: .backspace,
                width: 1.2,
                style: .utility
            )
        )

        let third = RowSpec(sideInset: 4, minHeight: Layout.rowHeight, keys: thirdKeys)
        let fourth = RowSpec(sideInset: 0, minHeight: Layout.bottomRowHeight, keys: bottomKeys(modeTitle: "ABC", modeAction: .setLayer(.letters)))

        return [first, second, third, fourth]
    }

    func characterKeys(_ characters: String) -> [KeySpec] {
        characters.map { character in
            let raw = String(character)
            let display = isShiftEnabled ? raw.uppercased() : raw
            return KeySpec(
                title: display,
                accessibilityLabel: raw.uppercased(),
                action: .text(raw),
                width: 1.0,
                style: .character
            )
        }
    }

    func textKeys(_ texts: [String]) -> [KeySpec] {
        texts.map { value in
            KeySpec(
                title: value,
                accessibilityLabel: value,
                action: .text(value),
                width: 1.0,
                style: .character
            )
        }
    }

    func bottomKeys(modeTitle: String, modeAction: KeyAction) -> [KeySpec] {
        [
            KeySpec(title: modeTitle, accessibilityLabel: modeTitle, action: modeAction, width: 1.55, style: .utility),
            KeySpec(symbolName: "globe", accessibilityLabel: "Next Keyboard", action: .nextKeyboard, width: 1.05, style: .utility),
            KeySpec(title: "space", accessibilityLabel: "Space", action: .space, width: 4.2, style: .action),
            KeySpec(symbolName: "return.left", accessibilityLabel: "Return", action: .enter, width: 1.65, style: .utility)
        ]
    }

    func makeRow(from rowSpec: RowSpec) -> UIView {
        let container = makeStackContainer(minHeight: rowSpec.minHeight)
        guard let stack = container.subviews.compactMap({ $0 as? UIStackView }).first else {
            return container
        }

        let leadingSpacer = UIView()
        leadingSpacer.backgroundColor = .clear
        let trailingSpacer = UIView()
        trailingSpacer.backgroundColor = .clear

        stack.addArrangedSubview(leadingSpacer)
        applyRow(specs: rowSpec.keys, to: stack)
        stack.addArrangedSubview(trailingSpacer)

        leadingSpacer.widthAnchor.constraint(equalToConstant: rowSpec.sideInset).isActive = true
        trailingSpacer.widthAnchor.constraint(equalToConstant: rowSpec.sideInset).isActive = true

        return container
    }

    func makeStackContainer(minHeight: CGFloat) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = Layout.keySpacing
        stack.alignment = .fill
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight)
        ])

        return container
    }

    func applyRow(specs: [KeySpec], to stack: UIStackView?) {
        guard let stack else {
            return
        }

        var baselineButton: UIButton?
        var baselineWidth: CGFloat = 1.0

        for spec in specs {
            let button = makeKeyButton(for: spec)
            stack.addArrangedSubview(button)

            if let baselineButton {
                button.widthAnchor.constraint(
                    equalTo: baselineButton.widthAnchor,
                    multiplier: spec.width / baselineWidth
                ).isActive = true
            } else {
                baselineButton = button
                baselineWidth = max(spec.width, 0.01)
            }
        }
    }

    func makeKeyButton(for key: KeySpec) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = keyBackgroundColor(for: key.style)
        button.layer.cornerRadius = key.style == .utility ? 7 : 8
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = resolvedInterfaceStyle() == .dark ? 0.22 : 0.06
        button.layer.shadowRadius = 0
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.setTitleColor(.label, for: .normal)

        if let title = key.title {
            button.setTitle(title, for: .normal)
        } else if let symbolName = key.symbolName {
            let symbolSize: CGFloat = key.style == .utility ? 16 : 17
            let imageConfig = UIImage.SymbolConfiguration(pointSize: symbolSize, weight: .semibold)
            let image = UIImage(systemName: symbolName, withConfiguration: imageConfig)
            button.setImage(image, for: .normal)
            button.tintColor = .label
        }

        button.accessibilityLabel = key.accessibilityLabel
        button.titleLabel?.lineBreakMode = .byClipping
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.7

        let tag = nextTag
        nextTag += 1
        actionByButtonTag[tag] = key.action
        keyStyleByTag[tag] = key.style
        button.tag = tag
        button.addTarget(self, action: #selector(onKeyTap(_:)), for: .touchUpInside)

        keyButtons.append(button)

        switch key.action {
        case .toggleShift:
            shiftButton = button
        case .toggleControl:
            controlButton = button
        case .toggleAlt:
            altButton = button
        case .toggleFunction:
            fnButton = button
        case .nextKeyboard:
            globeButton = button
        case .text(let value):
            let normalized = value.lowercased()
            if functionLayerAction(for: normalized) != nil {
                functionLayerTextButtons[normalized] = button
            }
        default:
            break
        }

        return button
    }

    func resolvedInterfaceStyle() -> UIUserInterfaceStyle {
        KeyboardThemePalette.resolvedInterfaceStyle(
            keyboardAppearance: textDocumentProxy.keyboardAppearance ?? .default,
            traitStyle: traitCollection.userInterfaceStyle
        )
    }

    func keyboardBackgroundColor() -> UIColor {
        KeyboardThemePalette.backgroundColor(for: resolvedInterfaceStyle())
    }

    func keyBackgroundColor(for style: KeyStyle) -> UIColor {
        KeyboardThemePalette.keyColor(
            for: keyVisualStyle(from: style),
            interfaceStyle: resolvedInterfaceStyle()
        )
    }

    func activeModifierColor() -> UIColor {
        KeyboardThemePalette.activeModifierColor(for: resolvedInterfaceStyle())
    }

    func keyVisualStyle(from style: KeyStyle) -> KeyboardThemePalette.KeyVisualStyle {
        switch style {
        case .character:
            return .character
        case .utility:
            return .utility
        case .action:
            return .action
        }
    }

    func applyTheme() {
        view.backgroundColor = keyboardBackgroundColor()
        rootStack.backgroundColor = keyboardBackgroundColor()

        let isDark = resolvedInterfaceStyle() == .dark
        for button in keyButtons {
            if let style = keyStyleByTag[button.tag] {
                button.backgroundColor = keyBackgroundColor(for: style)
            }
            button.setTitleColor(.label, for: .normal)
            button.tintColor = .label
            button.layer.shadowOpacity = isDark ? 0.22 : 0.06
        }
        updateModifierKeyAppearance()
        updateShiftKeyAppearance()
    }

    func updateKeyFonts() {
        let width = view.bounds.width
        let isCompact = width < 370
        let topSize: CGFloat = isCompact ? 12 : 13
        let keySize: CGFloat = isCompact ? 17 : 19
        let utilitySize: CGFloat = isCompact ? 16 : 17

        for button in keyButtons {
            let title = button.title(for: .normal) ?? ""
            if title.isEmpty {
                continue
            }

            let isTopUtility = button == controlButton || button == altButton || button == fnButton || title == "Esc" || title == "Tab"
            let isSystemKey = title == "space" || title == "123" || title == "ABC" || title == "#+="
            let targetSize = isTopUtility ? topSize : (isSystemKey ? utilitySize : keySize)
            let weight: UIFont.Weight = isTopUtility ? .semibold : .regular
            button.titleLabel?.font = UIFont.systemFont(ofSize: targetSize, weight: weight)
        }
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
            textDocumentProxy.insertText(" ")
        case .toggleControl:
            isControlEnabled.toggle()
            if isControlEnabled {
                isAltEnabled = false
            }
            updateModifierKeyAppearance()
        case .toggleAlt:
            isAltEnabled.toggle()
            if isAltEnabled {
                isControlEnabled = false
            }
            updateModifierKeyAppearance()
        case .toggleFunction:
            isFunctionEnabled.toggle()
            updateModifierKeyAppearance()
            updateFunctionLayerLegends()
        case .toggleShift:
            guard currentLayer == .letters else {
                return
            }
            isShiftEnabled.toggle()
            renderKeyboard()
        case .setLayer(let layer):
            currentLayer = layer
            if layer != .letters {
                isShiftEnabled = false
            }
            renderKeyboard()
        case .nextKeyboard:
            advanceToNextInputMode()
        case .home:
            textDocumentProxy.insertText("\u{001B}[H")
        case .end:
            textDocumentProxy.insertText("\u{001B}[F")
        case .pageUp:
            textDocumentProxy.insertText("\u{001B}[5~")
        case .pageDown:
            textDocumentProxy.insertText("\u{001B}[6~")
        }
    }

    func insertText(_ value: String) {
        if isFunctionEnabled, let fnAction = functionLayerAction(for: value.lowercased()) {
            apply(action: fnAction)
            return
        }

        let output: String
        if currentLayer == .letters {
            output = isShiftEnabled ? value.uppercased() : value.lowercased()
        } else {
            output = value
        }

        if isControlEnabled {
            defer {
                isControlEnabled = false
                updateModifierKeyAppearance()
            }

            guard output.count == 1, let scalar = output.unicodeScalars.first, scalar.isASCII else {
                textDocumentProxy.insertText(output)
                return
            }

            let ascii = UInt8(scalar.value)
            let controlValue = ascii & 0x1F
            if let controlScalar = UnicodeScalar(Int(controlValue)) {
                textDocumentProxy.insertText(String(controlScalar))
            } else {
                textDocumentProxy.insertText(output)
            }
        } else if isAltEnabled {
            defer {
                isAltEnabled = false
                updateModifierKeyAppearance()
            }
            textDocumentProxy.insertText("\u{001B}")
            textDocumentProxy.insertText(output)
        } else {
            textDocumentProxy.insertText(output)
        }

        if currentLayer == .letters && isShiftEnabled {
            isShiftEnabled = false
            renderKeyboard()
        }
    }

    func functionLayerAction(for value: String) -> KeyAction? {
        switch value {
        case "h":
            return .arrowLeft
        case "j":
            return .arrowDown
        case "k":
            return .arrowUp
        case "l":
            return .arrowRight
        case "u":
            return .home
        case "o":
            return .end
        case "i":
            return .pageUp
        case "p":
            return .pageDown
        default:
            return nil
        }
    }

    func updateModifierKeyAppearance() {
        let active = activeModifierColor()

        controlButton?.backgroundColor = isControlEnabled ? active : keyBackgroundColor(for: .utility)
        controlButton?.setTitleColor(isControlEnabled ? .white : .label, for: .normal)

        altButton?.backgroundColor = isAltEnabled ? active : keyBackgroundColor(for: .utility)
        altButton?.setTitleColor(isAltEnabled ? .white : .label, for: .normal)

        fnButton?.backgroundColor = isFunctionEnabled ? active : keyBackgroundColor(for: .utility)
        fnButton?.setTitleColor(isFunctionEnabled ? .white : .label, for: .normal)
    }

    func updateShiftKeyAppearance() {
        let active = activeModifierColor()
        shiftButton?.backgroundColor = isShiftEnabled ? active : keyBackgroundColor(for: .utility)
        shiftButton?.tintColor = isShiftEnabled ? .white : .label
    }

    func updateFunctionLayerLegends() {
        let fnLegends: [String: String] = [
            "h": "←",
            "j": "↓",
            "k": "↑",
            "l": "→",
            "u": "Home",
            "o": "End",
            "i": "Pg↑",
            "p": "Pg↓"
        ]

        for (value, button) in functionLayerTextButtons {
            if isFunctionEnabled, let legend = fnLegends[value] {
                button.setTitle(legend, for: .normal)
            } else {
                button.setTitle(isShiftEnabled ? value.uppercased() : value.lowercased(), for: .normal)
            }
        }
        updateKeyFonts()
    }
}
