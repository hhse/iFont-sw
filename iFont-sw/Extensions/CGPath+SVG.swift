import CoreGraphics
import SwiftUI

// MARK: - CGPath SVG Parser

extension CGPath {
    static func fromSVGPath(_ pathString: String) -> CGPath? {
        var path = Path()
        var currentPoint = CGPoint.zero
        var startPoint = CGPoint.zero
        var numbers: [CGFloat] = []
        var command = ""
        var i = pathString.startIndex

        while i < pathString.endIndex {
            let char = pathString[i]
            if char.isLetter {
                if !command.isEmpty && !numbers.isEmpty {
                    applyCommand(command, numbers: numbers, currentPoint: &currentPoint, startPoint: &startPoint, path: &path)
                    numbers = []
                }
                command = String(char)
                i = pathString.index(after: i)
            } else if char.isNumber || char == "." || char == "-" {
                var j = i
                while j < pathString.endIndex {
                    let c = pathString[j]
                    if c.isNumber || c == "." || c == "-" || (c == "e" && j > i) {
                        j = pathString.index(after: j)
                    } else {
                        break
                    }
                }
                if let num = Double(pathString[i..<j]) {
                    numbers.append(CGFloat(num))
                }
                i = j
            } else {
                i = pathString.index(after: i)
            }
        }
        if !command.isEmpty && !numbers.isEmpty {
            applyCommand(command, numbers: numbers, currentPoint: &currentPoint, startPoint: &startPoint, path: &path)
        }
        return path.cgPath
    }

    private static func applyCommand(_ cmd: String, numbers: [CGFloat], currentPoint: inout CGPoint, startPoint: inout CGPoint, path: inout Path) {
        switch cmd {
        case "M": path.move(to: CGPoint(x: numbers[0], y: numbers[1])); currentPoint = CGPoint(x: numbers[0], y: numbers[1]); startPoint = currentPoint
        case "m": let p = CGPoint(x: currentPoint.x + numbers[0], y: currentPoint.y + numbers[1]); path.move(to: p); currentPoint = p; startPoint = p
        case "L": path.addLine(to: CGPoint(x: numbers[0], y: numbers[1])); currentPoint = CGPoint(x: numbers[0], y: numbers[1])
        case "l": let p = CGPoint(x: currentPoint.x + numbers[0], y: currentPoint.y + numbers[1]); path.addLine(to: p); currentPoint = p
        case "H": path.addLine(to: CGPoint(x: numbers[0], y: currentPoint.y)); currentPoint.x = numbers[0]
        case "h": currentPoint.x += numbers[0]; path.addLine(to: currentPoint)
        case "V": path.addLine(to: CGPoint(x: currentPoint.x, y: numbers[0])); currentPoint.y = numbers[0]
        case "v": currentPoint.y += numbers[0]; path.addLine(to: currentPoint)
        case "C": path.addCurve(to: CGPoint(x: numbers[4], y: numbers[5]), control1: CGPoint(x: numbers[0], y: numbers[1]), control2: CGPoint(x: numbers[2], y: numbers[3])); currentPoint = CGPoint(x: numbers[4], y: numbers[5])
        case "c": let cp1 = CGPoint(x: currentPoint.x + numbers[0], y: currentPoint.y + numbers[1]); let cp2 = CGPoint(x: currentPoint.x + numbers[2], y: currentPoint.y + numbers[3]); let end = CGPoint(x: currentPoint.x + numbers[4], y: currentPoint.y + numbers[5]); path.addCurve(to: end, control1: cp1, control2: cp2); currentPoint = end
        case "Q": path.addQuadCurve(to: CGPoint(x: numbers[2], y: numbers[3]), control: CGPoint(x: numbers[0], y: numbers[1])); currentPoint = CGPoint(x: numbers[2], y: numbers[3])
        case "q": let end = CGPoint(x: currentPoint.x + numbers[2], y: currentPoint.y + numbers[3]); path.addQuadCurve(to: end, control: CGPoint(x: currentPoint.x + numbers[0], y: currentPoint.y + numbers[1])); currentPoint = end
        case "A": path.addLine(to: CGPoint(x: numbers[5], y: numbers[6])); currentPoint = CGPoint(x: numbers[5], y: numbers[6])
        case "a": let end = CGPoint(x: currentPoint.x + numbers[5], y: currentPoint.y + numbers[6]); path.addLine(to: end); currentPoint = end
        case "Z", "z": path.closeSubpath(); currentPoint = startPoint
        case "S": path.addQuadCurve(to: CGPoint(x: numbers[2], y: numbers[3]), control: CGPoint(x: numbers[0], y: numbers[1])); currentPoint = CGPoint(x: numbers[2], y: numbers[3])
        case "s": let end = CGPoint(x: currentPoint.x + numbers[2], y: currentPoint.y + numbers[3]); path.addQuadCurve(to: end, control: CGPoint(x: currentPoint.x + numbers[0], y: currentPoint.y + numbers[1])); currentPoint = end
        default: break
        }
    }
}