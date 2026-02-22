import UIKit

final class SetupViewController: UIViewController {
    private let stack = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let stepsLabel = UILabel()
    private let openSettingsButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureLayout()
    }
}

private extension SetupViewController {
    func configureView() {
        view.backgroundColor = UIColor(red: 0.08, green: 0.1, blue: 0.15, alpha: 1.0)

        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = "KeyTerm Keyboard"
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0

        subtitleLabel.text = "Terminal-friendly iOS keyboard with Esc, Ctrl, Tab, and arrow keys."
        subtitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        subtitleLabel.textColor = UIColor(white: 0.88, alpha: 1.0)
        subtitleLabel.numberOfLines = 0

        stepsLabel.text =
            """
            1. Open iOS Settings.
            2. Go to General -> Keyboard -> Keyboards.
            3. Add New Keyboard -> KeyTerm Keyboard.
            4. In terminal input, tap globe to switch keyboards.
            """
        stepsLabel.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
        stepsLabel.textColor = UIColor(white: 0.92, alpha: 1.0)
        stepsLabel.numberOfLines = 0

        openSettingsButton.setTitle("Open iOS Settings", for: .normal)
        openSettingsButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        openSettingsButton.setTitleColor(.white, for: .normal)
        openSettingsButton.backgroundColor = UIColor(red: 0.13, green: 0.52, blue: 0.98, alpha: 1.0)
        openSettingsButton.layer.cornerRadius = 12
        openSettingsButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 20, bottom: 14, right: 20)
        openSettingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
    }

    func configureLayout() {
        view.addSubview(stack)
        [titleLabel, subtitleLabel, stepsLabel, openSettingsButton].forEach(stack.addArrangedSubview)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28)
        ])
    }

    @objc
    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(settingsURL)
    }
}

