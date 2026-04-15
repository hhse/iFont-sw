import SwiftUI
import UIKit

// MARK: - Shared UIKit Weight Converter

func uiFontWeight(from swiftUIWeight: Font.Weight) -> UIFont.Weight {
    switch swiftUIWeight {
    case .ultraLight: return .ultraLight
    case .thin: return .thin
    case .light: return .light
    case .medium: return .medium
    case .semibold: return .semibold
    case .bold: return .bold
    case .heavy: return .heavy
    case .black: return .black
    default: return .regular
    }
}

// MARK: - Custom Font Text (使用自定义字体)

struct CustomFontText: UIViewRepresentable {
    let text: String
    let fontData: Data?
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let lineHeight: CGFloat

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .white
        label.lineBreakMode = .byWordWrapping
        label.clipsToBounds = true
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        var font: UIFont

        if let data = fontData {
            if let provider = CGDataProvider(data: data as CFData),
               let cgFont = CGFont(provider) {
                let ctFont = CTFontCreateWithGraphicsFont(cgFont, fontSize, nil, nil)
                font = ctFont as UIFont
            } else {
                font = UIFont.systemFont(ofSize: fontSize, weight: uiFontWeight(from: fontWeight))
            }
        } else {
            font = UIFont.systemFont(ofSize: fontSize, weight: uiFontWeight(from: fontWeight))
        }

        let lineSpacing = max(0, (lineHeight - 1) * fontSize)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]
        )
        uiView.attributedText = attributedText
    }

    typealias UIViewType = UILabel
}

// MARK: - Font Preview View

struct FontPreviewView: UIViewRepresentable {
    let fontData: Data?
    let fontName: String
    let previewText: String
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let lineHeight: CGFloat

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.04, alpha: 1)
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.subviews.forEach { $0.removeFromSuperview() }

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        uiView.addSubview(containerView)

        let nameLabel = UILabel()
        nameLabel.text = fontName
        nameLabel.font = .systemFont(ofSize: 11)
        nameLabel.textColor = .gray
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nameLabel)

        let label = UILabel()
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = uiView.bounds.width > 0 ? uiView.bounds.width - 20 : UIScreen.main.bounds.width - 40

        var finalFont: UIFont
        let weightValue = uiFontWeight(from: fontWeight)

        if let data = fontData {
            if let provider = CGDataProvider(data: data as CFData), let cgFont = CGFont(provider) {
                let ctFont = CTFontCreateWithGraphicsFont(cgFont, fontSize, nil, nil)
                finalFont = ctFont as UIFont
            } else {
                finalFont = .systemFont(ofSize: fontSize, weight: weightValue)
            }
        } else {
            finalFont = .systemFont(ofSize: fontSize, weight: weightValue)
        }

        label.font = finalFont

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = max(0, (lineHeight - 1) * fontSize)
        paragraphStyle.lineBreakMode = .byWordWrapping
        let attributedText = NSAttributedString(
            string: previewText,
            attributes: [
                .font: finalFont,
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]
        )
        label.attributedText = attributedText
        label.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(label)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: uiView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: uiView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: uiView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: uiView.bottomAnchor),

            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),

            label.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            label.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -10),
            label.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -20)
        ])
    }
}