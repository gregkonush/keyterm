import UIKit

final class KeyboardViewController: UIInputViewController {
    fileprivate enum KeyboardLayer {
        case letters
        case numbers
        case symbols
    }

    fileprivate enum Layout {
        static let horizontalInset: CGFloat = 6
        static let topInset: CGFloat = 0
        static let bottomInset: CGFloat = 4
        static let rowSpacing: CGFloat = 5
        static let keySpacing: CGFloat = 5
        static let topRowHeight: CGFloat = 24
        static let rowHeight: CGFloat = 44
        static let bottomRowHeight: CGFloat = 46
    }

    fileprivate enum DeleteRepeatTiming {
        static let initialDelay: TimeInterval = 0.36
        static let characterInterval: TimeInterval = 0.085
        static let wordInterval: TimeInterval = 0.16
        static let characterDeleteThreshold = 10
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
    private let keyHaptics = KeyboardHapticFeedback()
    private var deleteStartTimer: Timer?
    private var deleteRepeatTimer: Timer?
    private var deleteMode: DeleteRepeatMode = .character
    private var isDeleteKeyHeld = false
    private var didRunDeleteRepeat = false
    private var deleteRepeatCharacterCount = 0

    private var currentLayer: KeyboardLayer = .letters
    private var isShiftEnabled = false
    private var isControlEnabled = false
    private var isAltEnabled = false
    private var isFunctionEnabled = false

    deinit {
        stopDeleteHoldTracking()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureRootStack()
        renderKeyboard()
        prepareHaptics()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
        prepareHaptics()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        applyTheme()
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
    enum DeleteRepeatMode {
        case character
        case word
    }

    func configureRootStack() {
        rootStack.axis = .vertical
        rootStack.spacing = Layout.rowSpacing
        rootStack.alignment = .fill
        rootStack.distribution = .fill
        rootStack.translatesAutoresizingMaskIntoConstraints = false

        applyTheme()
        view.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.horizontalInset),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.horizontalInset),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: Layout.topInset),
            rootStack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -Layout.bottomInset)
        ])
    }

    func renderKeyboard() {
        stopDeleteHoldTracking()

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
            KeySpec(title: "Fn", accessibilityLabel: "Function and ANSI Cursor Mode", action: .toggleFunction, width: 1.0, style: .utility),
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
        container.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        container.setContentHuggingPriority(.defaultLow, for: .vertical)

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = Layout.keySpacing
        stack.alignment = .fill
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)

        let preferredHeight = container.heightAnchor.constraint(equalToConstant: minHeight)
        // Keep row heights as preferred values so iOS can fit wrapper insets without hard conflicts.
        preferredHeight.priority = UILayoutPriority(999)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            preferredHeight
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
        button.layer.cornerCurve = .continuous
        button.layer.cornerRadius = keyCornerRadius(for: key.style)
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
        button.addTarget(self, action: #selector(onKeyTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(onKeyTap(_:)), for: .touchUpInside)
        button.addTarget(
            self,
            action: #selector(onKeyTouchCancel(_:)),
            for: [.touchUpOutside, .touchCancel, .touchDragExit]
        )

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

    func keyCornerRadius(for style: KeyStyle) -> CGFloat {
        switch style {
        case .utility:
            return 9
        case .character, .action:
            return 10
        }
    }

    func resolvedInterfaceStyle() -> UIUserInterfaceStyle {
        let keyboardAppearance = textDocumentProxy.keyboardAppearance ?? .default
        if keyboardAppearance == .default {
            return resolvedTraitStyle()
        }

        return KeyboardThemePalette.resolvedInterfaceStyle(
            keyboardAppearance: keyboardAppearance,
            traitStyle: resolvedTraitStyle()
        )
    }

    func resolvedTraitStyle() -> UIUserInterfaceStyle {
        let candidates: [UIUserInterfaceStyle] = [
            view.window?.traitCollection.userInterfaceStyle ?? .unspecified,
            inputView?.traitCollection.userInterfaceStyle ?? .unspecified,
            traitCollection.userInterfaceStyle
        ]

        if let style = candidates.first(where: { $0 != .unspecified }) {
            return style
        }

        return .light
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
        view.backgroundColor = .clear
        view.isOpaque = false
        inputView?.backgroundColor = .clear
        inputView?.isOpaque = false
        rootStack.backgroundColor = .clear
        rootStack.arrangedSubviews.forEach { $0.backgroundColor = .clear }

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

        if case .backspace = action {
            let shouldSuppressTapDelete = didRunDeleteRepeat
            stopDeleteHoldTracking()
            if shouldSuppressTapDelete {
                return
            }
        }
        apply(action: action)
    }

    @objc
    func onKeyTouchDown(_ sender: UIButton) {
        guard let action = actionByButtonTag[sender.tag] else {
            return
        }
        performKeyHapticFeedback(for: action)

        if case .backspace = action {
            startDeleteHoldTracking()
        }
    }

    @objc
    func onKeyTouchCancel(_ sender: UIButton) {
        guard let action = actionByButtonTag[sender.tag] else {
            return
        }

        if case .backspace = action {
            stopDeleteHoldTracking()
        }
    }

    func prepareHaptics() {
        keyHaptics.prepare()
    }

    func performKeyHapticFeedback(for action: KeyAction) {
        // Keep keyboard-switch key silent to match system behavior.
        if case .nextKeyboard = action {
            return
        }

        keyHaptics.emitKeyTap()
    }

    func startDeleteHoldTracking() {
        stopDeleteHoldTracking()

        isDeleteKeyHeld = true
        didRunDeleteRepeat = false
        deleteMode = .character
        deleteRepeatCharacterCount = 0

        let timer = Timer(
            timeInterval: DeleteRepeatTiming.initialDelay,
            repeats: false
        ) { [weak self] _ in
            self?.beginDeleteRepeating()
        }
        deleteStartTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func beginDeleteRepeating() {
        guard isDeleteKeyHeld else {
            stopDeleteHoldTracking()
            return
        }

        didRunDeleteRepeat = true
        runDeleteRepeatTick()
        scheduleDeleteRepeatTimer(interval: DeleteRepeatTiming.characterInterval)
    }

    func scheduleDeleteRepeatTimer(interval: TimeInterval) {
        deleteRepeatTimer?.invalidate()
        deleteRepeatTimer = nil

        let timer = Timer(
            timeInterval: interval,
            repeats: true
        ) { [weak self] _ in
            self?.runDeleteRepeatTick()
        }
        deleteRepeatTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func runDeleteRepeatTick() {
        guard isDeleteKeyHeld else {
            stopDeleteHoldTracking()
            return
        }

        switch deleteMode {
        case .character:
            textDocumentProxy.deleteBackward()
            deleteRepeatCharacterCount += 1
            if deleteRepeatCharacterCount >= DeleteRepeatTiming.characterDeleteThreshold {
                deleteMode = .word
                scheduleDeleteRepeatTimer(interval: DeleteRepeatTiming.wordInterval)
            }
        case .word:
            deleteWordBackward()
        }
    }

    func deleteWordBackward() {
        guard
            let context = textDocumentProxy.documentContextBeforeInput,
            !context.isEmpty
        else {
            textDocumentProxy.deleteBackward()
            return
        }

        let deleteCount = KeyboardDeletePlanner.backwardDeleteCount(in: context)
        if deleteCount <= 0 {
            textDocumentProxy.deleteBackward()
            return
        }

        for _ in 0..<deleteCount {
            textDocumentProxy.deleteBackward()
        }
    }

    func stopDeleteHoldTracking() {
        isDeleteKeyHeld = false
        deleteMode = .character
        deleteRepeatCharacterCount = 0

        deleteStartTimer?.invalidate()
        deleteStartTimer = nil

        deleteRepeatTimer?.invalidate()
        deleteRepeatTimer = nil
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
            insertCursorKey(.up)
        case .arrowDown:
            insertCursorKey(.down)
        case .arrowLeft:
            insertCursorKey(.left)
        case .arrowRight:
            insertCursorKey(.right)
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
            insertCursorKey(.home)
        case .end:
            insertCursorKey(.end)
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

    func insertCursorKey(_ key: TerminalEscapeSequences.CursorKey) {
        var modifiers = TerminalEscapeSequences.Modifiers()
        if isAltEnabled {
            modifiers.insert(.alt)
        }
        if isControlEnabled {
            modifiers.insert(.control)
        }

        // Default mode targets browser terminals where ESC-prefixed keys are unreliable on iOS.
        if !isFunctionEnabled, modifiers.isEmpty, let readline = TerminalEscapeSequences.readlineNavigation(for: key) {
            textDocumentProxy.insertText(readline)
            return
        }

        let mode: TerminalEscapeSequences.CursorMode = .normal
        let sequence = TerminalEscapeSequences.cursorKey(key, mode: mode, modifiers: modifiers)
        textDocumentProxy.insertText(sequence)

        // Keep Alt/Ctrl one-shot for navigation keys, same behavior as character keys.
        if isAltEnabled || isControlEnabled {
            isAltEnabled = false
            isControlEnabled = false
            updateModifierKeyAppearance()
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

enum KeyboardDeletePlanner {
    static func backwardDeleteCount(in contextBeforeCursor: String) -> Int {
        guard !contextBeforeCursor.isEmpty else {
            return 0
        }

        let totalUTF16 = contextBeforeCursor.utf16.count
        let trailingWhitespaceUTF16 = trailingWhitespaceUTF16Count(in: contextBeforeCursor)
        let trimmedEndUTF16 = totalUTF16 - trailingWhitespaceUTF16

        guard trimmedEndUTF16 > 0 else {
            return contextBeforeCursor.count
        }

        let tokenizer = CFStringTokenizerCreate(
            kCFAllocatorDefault,
            contextBeforeCursor as CFString,
            CFRange(location: 0, length: totalUTF16),
            CFOptionFlags(kCFStringTokenizerUnitWordBoundary),
            Locale.current as CFLocale
        )

        let tokenType = CFStringTokenizerGoToTokenAtIndex(tokenizer, trimmedEndUTF16 - 1)
        let tokenRange = CFStringTokenizerGetCurrentTokenRange(tokenizer)

        guard
            tokenType.rawValue != 0,
            tokenRange.location != kCFNotFound,
            tokenRange.length > 0,
            tokenRange.location < trimmedEndUTF16,
            let tokenStart = stringIndex(atUTF16Offset: tokenRange.location, in: contextBeforeCursor)
        else {
            return fallbackDeleteCount(in: contextBeforeCursor)
        }

        return contextBeforeCursor[tokenStart..<contextBeforeCursor.endIndex].count
    }

    private static func trailingWhitespaceUTF16Count(in text: String) -> Int {
        let whitespaceSet = CharacterSet.whitespacesAndNewlines
        var count = 0

        for character in text.reversed() {
            guard isWhitespace(character, set: whitespaceSet) else {
                break
            }
            count += String(character).utf16.count
        }

        return count
    }

    private static func fallbackDeleteCount(in text: String) -> Int {
        let whitespaceSet = CharacterSet.whitespacesAndNewlines
        let characters = Array(text)

        var index = characters.count
        while index > 0, isWhitespace(characters[index - 1], set: whitespaceSet) {
            index -= 1
        }
        while index > 0, !isWhitespace(characters[index - 1], set: whitespaceSet) {
            index -= 1
        }

        return characters.count - index
    }

    private static func stringIndex(atUTF16Offset offset: Int, in text: String) -> String.Index? {
        guard offset >= 0, offset <= text.utf16.count else {
            return nil
        }

        let utf16Index = text.utf16.index(text.utf16.startIndex, offsetBy: offset)
        return String.Index(utf16Index, within: text)
    }

    private static func isWhitespace(_ character: Character, set: CharacterSet) -> Bool {
        character.unicodeScalars.allSatisfy { set.contains($0) }
    }
}
