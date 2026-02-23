import UIKit

enum KeyboardThemePalette {
    enum KeyVisualStyle {
        case character
        case utility
        case action
    }

    static func resolvedInterfaceStyle(
        keyboardAppearance: UIKeyboardAppearance,
        traitStyle: UIUserInterfaceStyle
    ) -> UIUserInterfaceStyle {
        switch keyboardAppearance {
        case .dark:
            return .dark
        case .light:
            return .light
        default:
            return traitStyle
        }
    }

    static func backgroundColor(for interfaceStyle: UIUserInterfaceStyle) -> UIColor {
        switch interfaceStyle {
        case .dark:
            return UIColor(red: 0.18, green: 0.19, blue: 0.22, alpha: 1.0)
        default:
            return UIColor(red: 0.80, green: 0.82, blue: 0.86, alpha: 1.0)
        }
    }

    static func keyColor(for keyStyle: KeyVisualStyle, interfaceStyle: UIUserInterfaceStyle) -> UIColor {
        switch interfaceStyle {
        case .dark:
            switch keyStyle {
            case .character:
                return UIColor(red: 0.35, green: 0.36, blue: 0.40, alpha: 1.0)
            case .utility:
                return UIColor(red: 0.47, green: 0.48, blue: 0.53, alpha: 1.0)
            case .action:
                return UIColor(red: 0.40, green: 0.41, blue: 0.46, alpha: 1.0)
            }
        default:
            switch keyStyle {
            case .character:
                return UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1.0)
            case .utility:
                return UIColor(red: 0.84, green: 0.86, blue: 0.89, alpha: 1.0)
            case .action:
                return UIColor(red: 0.88, green: 0.90, blue: 0.93, alpha: 1.0)
            }
        }
    }

    static func activeModifierColor(for interfaceStyle: UIUserInterfaceStyle) -> UIColor {
        switch interfaceStyle {
        case .dark:
            return UIColor(red: 0.30, green: 0.57, blue: 1.0, alpha: 1.0)
        default:
            return UIColor(red: 0.19, green: 0.47, blue: 0.95, alpha: 1.0)
        }
    }
}
