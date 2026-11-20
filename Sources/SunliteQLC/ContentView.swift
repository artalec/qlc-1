import SwiftUI

struct ContentView: View {
    @EnvironmentObject var client: QLCPlusClient
    @EnvironmentObject var document: LightingDocument

    @State private var activeTab: RibbonToolbar.RibbonTab = .controller
    @State private var host: String = "127.0.0.1"
    @State private var port: String = "9999"
    @State private var path: String = "/qlcplusWS"
    @State private var blackout: Bool = false
    @State private var showLog: Bool = false
    @State private var showConnectionSheet: Bool = false
    @State private var newSceneName: String = ""
    @State private var newSceneKind: SceneButtonKind = .scene
    @State private var hue: Double = 0
    @State private var saturation: Double = 0
    @State private var brightness: Double = 1

    var body: some View {
        VStack(spacing: 0) {
            RibbonToolbar(
                activeTab: $activeTab,
                blackout: $blackout,
                showLog: $showLog,
                showConnectionSheet: $showConnectionSheet
            )

            HSplitView {
                PagesPanel()
                    .frame(minWidth: 180, maxWidth: 240)

                mainWorkArea
                    .frame(minWidth: 520)

                scenePanel
                    .frame(minWidth: 240, maxWidth: 320)
            }

            if showLog {
                Divider()
                logPanel.frame(height: 140)
            }
        }
        .background(SunliteTheme.canvasBackground)
        .sheet(isPresented: $showConnectionSheet) {
            connectionSheet
        }
    }

    private var mainWorkArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                colorMixingSection
                Divider()
                faderGridSection
            }
            .padding(12)
        }
        .background(SunliteTheme.canvasBackground)
    }

    private var colorMixingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("COLOR MIXING")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(SunliteTheme.textDark.opacity(0.7))

            HStack(alignment: .top, spacing: 16) {
                ColorWheelView(hue: $hue, saturation: $saturation)

                Slider(value: $brightness, in: 0...1)
                    .frame(height: 140)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 30)
                    .tint(SunliteTheme.accentOrange)

                quickColorPalette

                Spacer()
            }
        }
        .padding(10)
        .background(SunliteTheme.panelLight)
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(SunliteTheme.panelDark, lineWidth: 0.5))
    }

    private var quickColorPalette: some View {
        let swatches: [Color] = [.red, .green, .blue, .yellow, .purple, .cyan, .white, .black]
        return LazyVGrid(columns: Array(repeating: GridItem(.fixed(22), spacing: 4), count: 4), spacing: 4) {
            ForEach(Array(swatches.enumerated()), id: \.offset) { _, color in
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: 22, height: 22)
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.black.opacity(0.3), lineWidth: 1))
            }
        }
    }

    private var faderGridSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CHANNELS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(SunliteTheme.textDark.opacity(0.7))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(0..<document.channelCount, id: \.self) { ch in
                    ChannelFaderView(channel: ch)
                }
            }
        }
    }

    private var scenePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SCENES / SWITCHES / CYCLES")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(SunliteTheme.textDark.opacity(0.7))

            HStack(spacing: 4) {
                TextField("Имя", text: $newSceneName)
                    .textFieldStyle(.roundedBorder)
                Picker("", selection: $newSceneKind) {
                    Text("Scene").tag(SceneButtonKind.scene)
                    Text("Switch").tag(SceneButtonKind.switchType)
                    Text("Cycle").tag(SceneButtonKind.cycle)
                }
                .frame(width: 90)
                Button("Save") {
                    guard !newSceneName.isEmpty else { return }
                    document.addScene(name: newSceneName, kind: newSceneKind, values: client.channelValues)
                    newSceneName = ""
                }
            }

            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 2), spacing: 6) {
                    ForEach(document.scenes) { lightScene in
                        SceneButtonView(lightScene: lightScene)
                    }
                }
            }
            Spacer()
        }
        .padding(10)
        .background(SunliteTheme.panelLight)
    }

    private var logPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(client.log.enumerated()), id: \.offset) { _, line in
                    Text(line).font(.system(size: 10, design: .monospaced))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6)
        }
        .background(Color.black)
        .foregroundColor(.green)
    }

    private var connectionSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Подключение к QLC+")
                .font(.headline)

            HStack {
                TextField("Host", text: $host)
                TextField("Port", text: $port)
                TextField("WS Path", text: $path)
            }
            .textFieldStyle(.roundedBorder)

            HStack {
                Button("Подключить") {
                    client.connect(host: host, port: Int(port) ?? 9999, path: path)
                    showConnectionSheet = false
                }
                .buttonStyle(.borderedProminent)

                Button("Отключить") {
                    client.disconnect()
                }

                Spacer()

                Button("Закрыть") {
                    showConnectionSheet = false
                }
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}
