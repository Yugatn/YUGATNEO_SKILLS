import SwiftUI

struct WheelChart: View {
    let rays: [WheelRay]
    private let radius: CGFloat = 112

    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let count = max(rays.count, 1)
            ZStack {
                ForEach(1...5, id: \.self) { ring in
                    WheelPolygon(values: Array(repeating: Double(ring) * 2, count: count))
                        .stroke(.gray.opacity(0.23), lineWidth: 1)
                }
                ForEach(rays.indices, id: \.self) { index in
                    let angle = Double(index) * .pi * 2 / Double(count) - .pi / 2
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: CGPoint(x: center.x + radius * CGFloat(cos(angle)),
                                                 y: center.y + radius * CGFloat(sin(angle))))
                    }
                    .stroke(.gray.opacity(0.3), lineWidth: 1)
                }
                WheelPolygon(values: rays.map { Double($0.desired) })
                    .stroke(.orange, lineWidth: 2)
                WheelPolygon(values: rays.map { Double($0.current) })
                    .fill(.blue.opacity(0.25))
                WheelPolygon(values: rays.map { Double($0.current) })
                    .stroke(.blue, lineWidth: 2)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .accessibilityLabel("Колесо: синий — сейчас, оранжевый — желаемое")
        }
        .frame(height: 250)
    }
}

private struct WheelPolygon: Shape {
    let values: [Double]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard !values.isEmpty else { return path }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.448
        for (index, value) in values.enumerated() {
            let angle = Double(index) * 2 * .pi / Double(values.count) - .pi / 2
            let distance = radius * CGFloat(min(10, max(0, value)) / 10)
            let point = CGPoint(x: center.x + distance * CGFloat(cos(angle)),
                                y: center.y + distance * CGFloat(sin(angle)))
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        if values.count > 2 { path.closeSubpath() }
        return path
    }
}
