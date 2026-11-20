import SwiftUI

/// Верхняя ribbon-панель в стиле Sunlite Suite 2: круглая App-кнопка слева,
/// вкладки Controller/Page/Button, крупные иконки с подписями под ними.
struct RibbonToolbar: View {
    @EnvironmentObject var client: QLCPlusClient
    @Binding var activeTab: RibbonTab
    @Binding var blackout: Bool
    @Binding var showLog: Bool
    @Binding var showConnectionSheet: Bool

    enum RibbonTab: String, CaseIterable {
        case controller = "Controller"
        case page = "Page"
        case button = "Button"
    }

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider()
            iconRow
            Divider()
        }
        .background(SunliteTheme.ribbonGradient)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            // Круглая оранжевая App-кнопка — аналог MS Office button
            Button {
                showConnectionSheet = true
            } label: {
                Circle()
                    .fill(SunliteTheme.accentOrange)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                    )
            }
            .buttonStyle(.plain)
            .padding(.leading, 8)
            .padding(.vertical, 4)

            ForEach(RibbonTab.allCases, id: \.self) { tab in
                Button {
                    activeTab = tab
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 12, weight: activeTab == tab ? .bold : .regular))
                        .foregroundColor(SunliteTheme.textDark)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(activeTab == tab ? Color.white.opacity(0.6) : Color.clear)
                        .overlay(
                            Rectangle()
                                .fill(activeTab == tab ? SunliteTheme.accentOrange : Color.clear)
                                .frame(height: 2),
                            alignment: .bottom
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            connectionIndicator
                .padding(.trailing, 12)
        }
        .frame(height: 30)
    }

    private var connectionIndicator: some View {
        let (color, label): (Color, String) = {
            switch client.status {
            case .connected: return (.green, "QLC+ ONLINE")
            case .connecting: return (.yellow, "QLC+ ...")
            case .disconnected: return (.gray, "QLC+ OFFLINE")
            case .failed: return (.red, "QLC+ ERROR")
            }
        }()
        return HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).font(.system(size: 10)).foregroundColor(SunliteTheme.textDark)
        }
    }

    private var iconRow: some View {
        HStack(alignment: .top, spacing: 10) {
            ribbonGroup("Show") {
                ribbonButton(system: "lock.fill", title: "Lock") { }
                ribbonButton(system: "folder.fill", title: "Open/Save") { showConnectionSheet = true }
                ribbonButton(system: "gearshape.fill", title: "Preferences") { }
            }
            groupDivider
            ribbonGroup("Windows") {
                ribbonButton(system: "doc.on.doc.fill", title: "Pages") { }
                ribbonButton(system: "lightbulb.fill", title: "Fixtures") { }
                ribbonButton(system: "square.stack.3d.up.fill", title: "Cycle") { }
                ribbonButton(system: "slider.vertical.3", title: "Console",
                             highlighted: true) { }
            }
            groupDivider
            ribbonGroup("Light") {
                ribbonButton(system: "sun.max.fill", title: "Dimmer\nFull") {
                    applyAll(255)
                }
                ribbonButton(system: "sun.min.fill", title: "Dimmer\nClosed") {
                    applyAll(0)
                }
                ribbonButton(system: blackout ? "eye.slash.fill" : "eye.fill",
                             title: "Blackout", highlighted: blackout) {
                    blackout.toggle()
                    applyAll(blackout ? 0 : nil)
                }
            }
            groupDivider
            ribbonGroup("Debug") {
                ribbonButton(system: "terminal.fill", title: "Log", highlighted: showLog) {
                    showLog.toggle()
                }
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private var groupDivider: some View {
        Divider().frame(height: 50)
    }

    private func ribbonGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) { content() }
            Text(title)
                .font(.system(size: 9))
                .foregroundColor(SunliteTheme.textDark.opacity(0.7))
        }
    }

    private func ribbonButton(system: String, title: String, highlighted: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: system)
                    .font(.system(size: 18))
                    .foregroundColor(highlighted ? .white : SunliteTheme.textDark)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(highlighted ? SunliteTheme.accentOrange : Color.white.opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(SunliteTheme.panelDark, lineWidth: 0.5)
                    )
                Text(title)
                    .font(.system(size: 8))
                    .foregroundColor(SunliteTheme.textDark)
                    .multilineTextAlignment(.center)
                    .frame(width: 44)
            }
        }
        .buttonStyle(.plain)
    }

    private func applyAll(_ value: UInt8?) {
        // value == nil означает "вернуть к последним известным уровням"
        // применяется из ContentView через blackout-логику; здесь — заглушка
        // для кнопок Dimmer Full/Closed прямого ribbon-доступа.
        guard let value else { return }
        for ch in client.channelValues.keys {
            client.setChannel(ch, value: value)
        }
    }
}
