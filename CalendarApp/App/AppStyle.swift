//import UIKit
//
//enum AppStyle {
//    static let background = UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1.0)
//    static let cardBackground = UIColor.white
//    static let primary = UIColor(red: 0.22, green: 0.43, blue: 0.92, alpha: 1.0)
//    static let primarySoft = UIColor(red: 0.90, green: 0.93, blue: 1.00, alpha: 1.0)
//    static let textPrimary = UIColor(red: 0.08, green: 0.10, blue: 0.16, alpha: 1.0)
//    static let textSecondary = UIColor(red: 0.43, green: 0.47, blue: 0.56, alpha: 1.0)
//    static let separator = UIColor(red: 0.89, green: 0.91, blue: 0.95, alpha: 1.0)
//    static let success = UIColor(red: 0.20, green: 0.72, blue: 0.44, alpha: 1.0)
//
//    static let screenPadding: CGFloat = 20
//    static let cardCornerRadius: CGFloat = 20
//    static let controlCornerRadius: CGFloat = 16
//}

import UIKit

enum AppStyle {

    // MARK: - Colors

    static let background = UIColor(
        red: 0.965,
        green: 0.957,
        blue: 0.988,
        alpha: 1.0
    )

    static let cardBackground = UIColor(
        red: 1.000,
        green: 0.996,
        blue: 0.984,
        alpha: 1.0
    )

    static let primary = UIColor(
        red: 0.392,
        green: 0.318,
        blue: 0.839,
        alpha: 1.0
    )

    static let primarySoft = UIColor(
        red: 0.898,
        green: 0.878,
        blue: 1.000,
        alpha: 1.0
    )

    static let accent = UIColor(
        red: 1.000,
        green: 0.565,
        blue: 0.451,
        alpha: 1.0
    )

    static let accentSoft = UIColor(
        red: 1.000,
        green: 0.902,
        blue: 0.859,
        alpha: 1.0
    )

    static let textPrimary = UIColor(
        red: 0.141,
        green: 0.129,
        blue: 0.224,
        alpha: 1.0
    )

    static let textSecondary = UIColor(
        red: 0.482,
        green: 0.455,
        blue: 0.604,
        alpha: 1.0
    )

    static let textMuted = UIColor(
        red: 0.655,
        green: 0.627,
        blue: 0.749,
        alpha: 1.0
    )

    static let separator = UIColor(
        red: 0.894,
        green: 0.878,
        blue: 0.941,
        alpha: 1.0
    )

    static let success = UIColor(
        red: 0.227,
        green: 0.659,
        blue: 0.514,
        alpha: 1.0
    )

    // MARK: - Layout

    static let screenPadding: CGFloat = 20
    static let cardCornerRadius: CGFloat = 20
    static let controlCornerRadius: CGFloat = 16
}

extension UIView {
    func applyCardStyle(cornerRadius: CGFloat = AppStyle.cardCornerRadius) {
        backgroundColor = AppStyle.cardBackground
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.shadowRadius = 18
    }

    func applySoftShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.10
        layer.shadowOffset = CGSize(width: 0, height: 10)
        layer.shadowRadius = 22
    }
}

extension UIButton {
    func applyPrimaryButtonStyle() {
        backgroundColor = AppStyle.primary
        setTitleColor(.white, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        layer.cornerRadius = AppStyle.controlCornerRadius
        layer.cornerCurve = .continuous
        applySoftShadow()
    }
}

extension UITextField {
    func applyInputStyle() {
        backgroundColor = AppStyle.cardBackground
        textColor = AppStyle.textPrimary
        tintColor = AppStyle.primary
        font = .systemFont(ofSize: 17, weight: .regular)
        layer.cornerRadius = AppStyle.controlCornerRadius
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = AppStyle.separator.cgColor
    }
}

extension UITextView {
    func applyInputStyle() {
        backgroundColor = AppStyle.cardBackground
        textColor = AppStyle.textPrimary
        tintColor = AppStyle.primary
        font = .systemFont(ofSize: 17, weight: .regular)
        layer.cornerRadius = AppStyle.controlCornerRadius
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = AppStyle.separator.cgColor
        textContainerInset = UIEdgeInsets(top: 14, left: 10, bottom: 14, right: 10)
    }
}
