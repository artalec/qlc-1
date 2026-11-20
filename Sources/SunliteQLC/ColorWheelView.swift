import SwiftUI

/// Круглое HSV цветовое колесо, как в блоке "Color Mixing" Sunlite Suite 2:
/// клик/тап по кругу выбирает оттенок и насыщенность, рядом — отдельный
/// вертикальный слайдер яркости (передаётся снаружи через value binding).
struct ColorWheelView: View {
    @Binding var hue: Double        // 0...1
    @Binding var saturation: Double // 0...1
    var diameter: CGFloat = 140

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: hueGradientColors),
                        center: .center
                    )
                )
                .overlay(
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white, .white.opacity(0)],
                                center: .center,
                                startRadius: 0,
                                endRadius: diameter / 2
                            )
                        )
                )
                .overlay(Circle().stroke(SunliteTheme.panelDark, lineWidth: 2))
                .frame(width: diameter, height: diameter)

            // Индикатор текущей позиции
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .background(Circle().fill(currentColor))
                .frame(width: 14, height: 14)
                .offset(indicatorOffset)
                .shadow(radius: 1)
        }
        .frame(width: diameter, height: diameter)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { drag in
                    updateFromPoint(drag.location)
                }
        )
    }

    private var hueGradientColors: [Color] {
        stride(from: 0.0, through: 1.0, by: 1.0 / 12.0).map {
            Color(hue: $0, saturation: 1, brightness: 1)
        }
    }

    private var currentColor: Color {
        Color(hue: hue, saturation: saturation, brightness: 1)
    }

    private var indicatorOffset: CGSize {
        let radius = (diameter / 2) * saturation
        let angle = hue * 2 * .pi
        return CGSize(width: cos(angle) * radius, height: sin(angle) * radius)
    }

    private func updateFromPoint(_ point: CGPoint) {
        let center = CGPoint(x: diameter / 2, y: diameter / 2)
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distance = min(sqrt(dx * dx + dy * dy), diameter / 2)
        var angle = atan2(dy, dx)
        if angle < 0 { angle += 2 * .pi }
        hue = angle / (2 * .pi)
        saturation = distance / (diameter / 2)
    }
}
