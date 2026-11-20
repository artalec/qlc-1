import SwiftUI

/// Кнопка сцены с цветовой кодировкой по типу — точно по описанию
/// официального руководства Sunlite Suite 2: Scenes (yellow buttons),
/// Switches (red buttons), Cycles (blue buttons).
struct SceneButtonView: View {
    @EnvironmentObject var client: QLCPlusClient
    @EnvironmentObject var document: LightingDocument
    let lightScene: LightScene

    private var baseColor: Color {
        switch lightScene.kind {
        case .scene: return SunliteTheme.sceneYellow
        case .switchType: return SunliteTheme.switchRed
        case .cycle: return SunliteTheme.cycleBlue
        }
    }

    var body: some View {
        Button {
            recall()
        } label: {
            VStack(spacing: 2) {
                Text(lightScene.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 4)
            .background(
                LinearGradient(
                    colors: [baseColor.opacity(0.95), baseColor.opacity(0.7)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.black.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                document.deleteScene(lightScene)
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
    }

    private func recall() {
        for (channel, level) in lightScene.values {
            client.setChannel(channel, value: level)
        }
    }
}
