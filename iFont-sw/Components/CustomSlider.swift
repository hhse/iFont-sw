import SwiftUI

// MARK: - Custom Slider with Adjustable Thumb Size

struct CustomSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let thumbSize: CGFloat

    init(value: Binding<Double>, in range: ClosedRange<Double>, step: Double = 1, thumbSize: CGFloat = 24) {
        self._value = value
        self.range = range
        self.step = step
        self.thumbSize = thumbSize
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let normalizedValue = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let thumbPosition = CGFloat(normalizedValue) * (width - thumbSize)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)

                Capsule()
                    .fill(Color.gray)
                    .frame(width: thumbPosition + thumbSize / 2, height: 4)

                Circle()
                    .fill(Color.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                    .offset(x: thumbPosition)
            }
            .frame(height: thumbSize)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let newPosition = max(0, min(gesture.location.x - thumbSize / 2, width - thumbSize))
                        let newNormalizedValue = newPosition / (width - thumbSize)
                        let newValue = range.lowerBound + Double(newNormalizedValue) * (range.upperBound - range.lowerBound)
                        let steppedValue = round(newValue / step) * step
                        value = max(range.lowerBound, min(steppedValue, range.upperBound))
                    }
            )
        }
        .frame(height: thumbSize)
    }
}