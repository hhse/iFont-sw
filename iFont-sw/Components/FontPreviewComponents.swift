import SwiftUI

// MARK: - Font Weight Preview Components

struct FontPreviewList: View {
    let fileNames: [String]
    let loadedFontData: [Data]
    let previewText: String
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let lineHeight: CGFloat
    let totalCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(0..<fileNames.count, id: \.self) { index in
                PreviewItemView(
                    fontData: index < loadedFontData.count ? loadedFontData[index] : nil,
                    fontName: fileNames[index],
                    previewText: previewText,
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    lineHeight: lineHeight
                )

                if index < fileNames.count - 1 {
                    Divider()
                        .background(Color.gray.opacity(0.2))
                }
            }

            if totalCount > 3 {
                HStack {
                    Text("...及其他 \(totalCount - 3) 个文件")
                    Spacer()
                }
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
            }
        }
        .background(Color(white: 0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(8)
    }
}

struct PreviewItemView: View {
    let fontData: Data?
    let fontName: String
    let previewText: String
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let lineHeight: CGFloat

    private var previewFont: Font {
        if let data = fontData, let customFont = FontCache.shared.font(from: data, size: fontSize) {
            return customFont
        }
        return .system(size: fontSize, weight: fontWeight)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(fontName)
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .lineLimit(1)

            Text(previewText)
                .font(previewFont)
                .foregroundColor(.white)
                .lineLimit(2)
                .lineSpacing((lineHeight - 1) * fontSize)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.04))
    }
}