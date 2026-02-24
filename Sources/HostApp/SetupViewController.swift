import UIKit

final class SetupViewController: UIViewController {
    private enum StorageKeys {
        static let openedSettings = "setup.openedKeyboardSettings"
        static let completedSetup = "setup.completedKeyboardSetup"
    }

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let rootStack = UIStackView()

    private let headerStack = UIStackView()
    private let eyebrowLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let statusCard = UIView()
    private let statusIconView = UIImageView()
    private let statusTitleLabel = UILabel()
    private let statusBodyLabel = UILabel()

    private let stepsCard = UIView()
    private let stepsTitleLabel = UILabel()
    private let stepsPathLabel = UILabel()
    private let stepsStack = UIStackView()

    private let actionsStack = UIStackView()
    private let openSettingsButton = UIButton(type: .system)
    private let confirmEnabledButton = UIButton(type: .system)
    private let openFallbackSettingsButton = UIButton(type: .system)

    private var hasOpenedSettings = UserDefaults.standard.bool(forKey: StorageKeys.openedSettings)
    private var hasCompletedSetup = UserDefaults.standard.bool(forKey: StorageKeys.completedSetup)

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureLayout()
        configureActions()
        refreshUI()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

private extension SetupViewController {
    func configureView() {
        view.backgroundColor = .systemGroupedBackground

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        rootStack.translatesAutoresizingMaskIntoConstraints = false

        rootStack.axis = .vertical
        rootStack.alignment = .fill
        rootStack.spacing = 14

        configureHeader()
        configureStatusCard()
        configureStepsCard()
        configureButtons()
    }

    func configureHeader() {
        headerStack.axis = .vertical
        headerStack.alignment = .fill
        headerStack.spacing = 6
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        eyebrowLabel.text = "FIRST-TIME SETUP"
        eyebrowLabel.textColor = .tertiaryLabel
        eyebrowLabel.font = .preferredFont(forTextStyle: .caption1).withWeight(.semibold)
        eyebrowLabel.adjustsFontForContentSizeCategory = true

        titleLabel.text = "Enable KeyTerm Keyboard"
        titleLabel.textColor = .label
        titleLabel.font = .preferredFont(forTextStyle: .largeTitle).withWeight(.bold)
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true

        subtitleLabel.text = "Add KeyTerm, allow Full Access for haptics, then switch from globe in terminal input."
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.font = .preferredFont(forTextStyle: .body)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.adjustsFontForContentSizeCategory = true

        [eyebrowLabel, titleLabel, subtitleLabel].forEach(headerStack.addArrangedSubview)
    }

    func configureStatusCard() {
        statusCard.translatesAutoresizingMaskIntoConstraints = false
        statusCard.backgroundColor = .secondarySystemGroupedBackground
        statusCard.layer.cornerRadius = 14
        statusCard.layer.borderWidth = 1
        statusCard.layer.borderColor = UIColor.separator.withAlphaComponent(0.35).cgColor

        statusIconView.translatesAutoresizingMaskIntoConstraints = false
        statusIconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)

        statusTitleLabel.textColor = .label
        statusTitleLabel.font = .preferredFont(forTextStyle: .headline)
        statusTitleLabel.adjustsFontForContentSizeCategory = true

        statusBodyLabel.textColor = .secondaryLabel
        statusBodyLabel.font = .preferredFont(forTextStyle: .subheadline)
        statusBodyLabel.adjustsFontForContentSizeCategory = true
        statusBodyLabel.numberOfLines = 0
    }

    func configureStepsCard() {
        stepsCard.translatesAutoresizingMaskIntoConstraints = false
        stepsCard.backgroundColor = .secondarySystemGroupedBackground
        stepsCard.layer.cornerRadius = 14
        stepsCard.layer.borderWidth = 1
        stepsCard.layer.borderColor = UIColor.separator.withAlphaComponent(0.35).cgColor

        stepsTitleLabel.text = "Setup steps"
        stepsTitleLabel.textColor = .label
        stepsTitleLabel.font = .preferredFont(forTextStyle: .headline)
        stepsTitleLabel.adjustsFontForContentSizeCategory = true

        stepsPathLabel.text = "Settings -> General -> Keyboard -> Keyboards"
        stepsPathLabel.textColor = .tertiaryLabel
        stepsPathLabel.font = .monospacedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .footnote).pointSize, weight: .regular)
        stepsPathLabel.adjustsFontSizeToFitWidth = true
        stepsPathLabel.minimumScaleFactor = 0.8

        stepsStack.axis = .vertical
        stepsStack.alignment = .fill
        stepsStack.spacing = 8
        stepsStack.translatesAutoresizingMaskIntoConstraints = false

        let rows = [
            makeStepRow(index: 1, text: "Open Keyboard Settings"),
            makeStepRow(index: 2, text: "Add KeyTerm Keyboard"),
            makeStepRow(index: 3, text: "Enable Allow Full Access"),
            makeStepRow(index: 4, text: "In terminal input, switch with globe")
        ]
        rows.forEach(stepsStack.addArrangedSubview)
    }

    func configureButtons() {
        actionsStack.axis = .vertical
        actionsStack.alignment = .fill
        actionsStack.spacing = 10

        var primary = UIButton.Configuration.filled()
        primary.cornerStyle = .large
        primary.baseBackgroundColor = .systemBlue
        primary.baseForegroundColor = .white
        primary.image = UIImage(systemName: "keyboard")
        primary.imagePadding = 8
        primary.contentInsets = NSDirectionalEdgeInsets(top: 13, leading: 16, bottom: 13, trailing: 16)
        primary.attributedTitle = AttributedString(
            "Open Keyboard Settings",
            attributes: AttributeContainer([.font: UIFont.preferredFont(forTextStyle: .headline)])
        )
        openSettingsButton.configuration = primary

        var secondary = UIButton.Configuration.tinted()
        secondary.cornerStyle = .large
        secondary.baseBackgroundColor = .systemGreen.withAlphaComponent(0.18)
        secondary.baseForegroundColor = .systemGreen
        secondary.image = UIImage(systemName: "checkmark.circle")
        secondary.imagePadding = 8
        secondary.contentInsets = NSDirectionalEdgeInsets(top: 13, leading: 16, bottom: 13, trailing: 16)
        secondary.attributedTitle = AttributedString(
            "I've Enabled KeyTerm",
            attributes: AttributeContainer([.font: UIFont.preferredFont(forTextStyle: .headline)])
        )
        confirmEnabledButton.configuration = secondary

        var tertiary = UIButton.Configuration.plain()
        tertiary.baseForegroundColor = .secondaryLabel
        tertiary.image = UIImage(systemName: "slider.horizontal.3")
        tertiary.imagePadding = 6
        tertiary.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 4, bottom: 6, trailing: 4)
        tertiary.attributedTitle = AttributedString(
            "Open App Settings",
            attributes: AttributeContainer([.font: UIFont.preferredFont(forTextStyle: .subheadline)])
        )
        openFallbackSettingsButton.configuration = tertiary
        openFallbackSettingsButton.isHidden = true
    }

    func configureLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(rootStack)

        rootStack.addArrangedSubview(headerStack)
        rootStack.addArrangedSubview(statusCard)
        rootStack.addArrangedSubview(stepsCard)
        rootStack.addArrangedSubview(actionsStack)

        [openSettingsButton, confirmEnabledButton, openFallbackSettingsButton].forEach(actionsStack.addArrangedSubview)

        statusCard.addSubview(statusIconView)
        statusCard.addSubview(statusTitleLabel)
        statusCard.addSubview(statusBodyLabel)
        [statusIconView, statusTitleLabel, statusBodyLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        stepsCard.addSubview(stepsTitleLabel)
        stepsCard.addSubview(stepsPathLabel)
        stepsCard.addSubview(stepsStack)
        [stepsTitleLabel, stepsPathLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            rootStack.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            rootStack.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            rootStack.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 18),
            rootStack.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -24),

            statusIconView.leadingAnchor.constraint(equalTo: statusCard.leadingAnchor, constant: 12),
            statusIconView.topAnchor.constraint(equalTo: statusCard.topAnchor, constant: 12),
            statusIconView.widthAnchor.constraint(equalToConstant: 18),
            statusIconView.heightAnchor.constraint(equalToConstant: 18),

            statusTitleLabel.leadingAnchor.constraint(equalTo: statusIconView.trailingAnchor, constant: 8),
            statusTitleLabel.topAnchor.constraint(equalTo: statusCard.topAnchor, constant: 10),
            statusTitleLabel.trailingAnchor.constraint(equalTo: statusCard.trailingAnchor, constant: -12),

            statusBodyLabel.leadingAnchor.constraint(equalTo: statusTitleLabel.leadingAnchor),
            statusBodyLabel.topAnchor.constraint(equalTo: statusTitleLabel.bottomAnchor, constant: 3),
            statusBodyLabel.trailingAnchor.constraint(equalTo: statusCard.trailingAnchor, constant: -12),
            statusBodyLabel.bottomAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: -10),

            stepsTitleLabel.leadingAnchor.constraint(equalTo: stepsCard.leadingAnchor, constant: 12),
            stepsTitleLabel.topAnchor.constraint(equalTo: stepsCard.topAnchor, constant: 12),
            stepsTitleLabel.trailingAnchor.constraint(equalTo: stepsCard.trailingAnchor, constant: -12),

            stepsPathLabel.leadingAnchor.constraint(equalTo: stepsTitleLabel.leadingAnchor),
            stepsPathLabel.topAnchor.constraint(equalTo: stepsTitleLabel.bottomAnchor, constant: 4),
            stepsPathLabel.trailingAnchor.constraint(equalTo: stepsCard.trailingAnchor, constant: -12),

            stepsStack.leadingAnchor.constraint(equalTo: stepsCard.leadingAnchor, constant: 12),
            stepsStack.trailingAnchor.constraint(equalTo: stepsCard.trailingAnchor, constant: -12),
            stepsStack.topAnchor.constraint(equalTo: stepsPathLabel.bottomAnchor, constant: 10),
            stepsStack.bottomAnchor.constraint(equalTo: stepsCard.bottomAnchor, constant: -12)
        ])
    }

    func configureActions() {
        openSettingsButton.addTarget(self, action: #selector(openKeyboardSettings), for: .touchUpInside)
        confirmEnabledButton.addTarget(self, action: #selector(confirmKeyboardEnabled), for: .touchUpInside)
        openFallbackSettingsButton.addTarget(self, action: #selector(openFallbackSettings), for: .touchUpInside)
    }

    func makeStepRow(index: Int, text: String) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10

        let badge = UILabel()
        badge.text = "\(index)"
        badge.textAlignment = .center
        badge.font = .preferredFont(forTextStyle: .footnote).withWeight(.semibold)
        badge.textColor = .systemBlue
        badge.backgroundColor = .systemBlue.withAlphaComponent(0.14)
        badge.layer.cornerRadius = 11
        badge.clipsToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false

        let textLabel = UILabel()
        textLabel.text = text
        textLabel.textColor = .label
        textLabel.font = .preferredFont(forTextStyle: .body).withWeight(.medium)
        textLabel.adjustsFontForContentSizeCategory = true
        textLabel.numberOfLines = 0

        NSLayoutConstraint.activate([
            badge.widthAnchor.constraint(equalToConstant: 22),
            badge.heightAnchor.constraint(equalToConstant: 22)
        ])

        row.addArrangedSubview(badge)
        row.addArrangedSubview(textLabel)
        return row
    }

    func refreshUI() {
        if hasCompletedSetup {
            statusCard.backgroundColor = .systemGreen.withAlphaComponent(0.14)
            statusCard.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.32).cgColor
            statusIconView.image = UIImage(systemName: "checkmark.seal.fill")
            statusIconView.tintColor = .systemGreen
            statusTitleLabel.text = "Keyboard ready"
            statusBodyLabel.text = "In terminal input, tap globe and choose KeyTerm."
            confirmEnabledButton.isEnabled = false
            confirmEnabledButton.alpha = 0.55
        } else if hasOpenedSettings {
            statusCard.backgroundColor = .systemBlue.withAlphaComponent(0.12)
            statusCard.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.28).cgColor
            statusIconView.image = UIImage(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
            statusIconView.tintColor = .systemBlue
            statusTitleLabel.text = "Finish setup"
            statusBodyLabel.text = "Add KeyTerm, enable Full Access, then return and confirm."
            confirmEnabledButton.isEnabled = true
            confirmEnabledButton.alpha = 1
        } else {
            statusCard.backgroundColor = .secondarySystemGroupedBackground
            statusCard.layer.borderColor = UIColor.separator.withAlphaComponent(0.35).cgColor
            statusIconView.image = UIImage(systemName: "1.circle.fill")
            statusIconView.tintColor = .systemBlue
            statusTitleLabel.text = "Step 1 of 4"
            statusBodyLabel.text = "Open Keyboard Settings to start."
            confirmEnabledButton.isEnabled = true
            confirmEnabledButton.alpha = 1
        }
    }

    @objc
    func onDidBecomeActive() {
        if hasOpenedSettings, !hasCompletedSetup {
            refreshUI()
        }
    }

    @objc
    func openKeyboardSettings() {
        let urls = [
            URL(string: "App-prefs:root=General&path=Keyboard/KEYBOARDS"),
            URL(string: "App-prefs:root=General&path=Keyboard"),
            URL(string: "App-prefs:General&path=Keyboard"),
            URL(string: "prefs:root=General&path=Keyboard"),
            URL(string: UIApplication.openSettingsURLString)
        ].compactMap { $0 }

        openFirstReachableSettingsURL(urls, index: 0)
    }

    @objc
    func confirmKeyboardEnabled() {
        hasCompletedSetup = true
        UserDefaults.standard.set(true, forKey: StorageKeys.completedSetup)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        refreshUI()
    }

    @objc
    func openFallbackSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func openFirstReachableSettingsURL(_ urls: [URL], index: Int) {
        guard index < urls.count else {
            openFallbackSettingsButton.isHidden = false
            showManualPathAlert()
            return
        }

        UIApplication.shared.open(urls[index], options: [:]) { [weak self] success in
            guard let self else {
                return
            }
            if success {
                self.hasOpenedSettings = true
                UserDefaults.standard.set(true, forKey: StorageKeys.openedSettings)
                self.refreshUI()
                return
            }
            self.openFirstReachableSettingsURL(urls, index: index + 1)
        }
    }

    func showManualPathAlert() {
        let message =
            "Settings -> General -> Keyboard -> Keyboards -> Add New Keyboard... -> KeyTerm Keyboard -> Allow Full Access"
        let alert = UIAlertController(title: "Open Manually", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Open App Settings", style: .default) { [weak self] _ in
            self?.openFallbackSettings()
        })
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }
}

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: weight]
        ])
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
