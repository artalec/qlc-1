import Foundation

/// Страница приборов — аналог "Page" в Sunlite Suite 2 (например, _MASTER, MOVING HEAD).
/// Задаёт диапазон каналов, которые показываются при выборе этой страницы.
struct FixturePage: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var channelRangeStart: Int
    var channelRangeEnd: Int
    var isMaster: Bool = false
}

/// Тип кнопки сцены — в Sunlite Suite 2 цвет кнопки кодирует её тип:
/// Scene (жёлтый) / Switch (красный) / Cycle (синий).
enum SceneButtonKind: String, Codable, CaseIterable {
    case scene, switchType, cycle
}

/// Снимок уровней каналов, сохранённый под именем — аналог "сцены"/"preset" в Sunlite Suite.
struct LightScene: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var kind: SceneButtonKind
    var values: [Int: UInt8] // channel index (0-based) -> level 0...255

    init(name: String, kind: SceneButtonKind = .scene, values: [Int: UInt8]) {
        self.id = UUID()
        self.name = name
        self.kind = kind
        self.values = values
    }

    private enum CodingKeys: String, CodingKey { case id, name, kind, values }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        kind = try container.decodeIfPresent(SceneButtonKind.self, forKey: .kind) ?? .scene
        let raw = try container.decode([String: UInt8].self, forKey: .values)
        values = Dictionary(uniqueKeysWithValues: raw.compactMap { key, value in
            Int(key).map { ($0, value) }
        })
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(kind, forKey: .kind)
        let raw = Dictionary(uniqueKeysWithValues: values.map { (String($0.key), $0.value) })
        try container.encode(raw, forKey: .values)
    }
}

/// Хранилище страниц, сцен и настроек проекта, персистентное между запусками.
@MainActor
final class LightingDocument: ObservableObject {
    @Published var channelCount: Int = 48
    @Published var scenes: [LightScene] = []
    @Published var pages: [FixturePage] = [
        FixturePage(name: "_MASTER", channelRangeStart: 0, channelRangeEnd: 47, isMaster: true),
        FixturePage(name: "MOVING HEAD", channelRangeStart: 0, channelRangeEnd: 15),
        FixturePage(name: "PAR LED", channelRangeStart: 16, channelRangeEnd: 31)
    ]
    @Published var selectedPageID: UUID?

    private var storeURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SunliteQLC", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("scenes.json")
    }

    init() {
        load()
        selectedPageID = pages.first?.id
    }

    func addScene(name: String, kind: SceneButtonKind, values: [Int: UInt8]) {
        scenes.append(LightScene(name: name, kind: kind, values: values))
        save()
    }

    func deleteScene(_ scene: LightScene) {
        scenes.removeAll { $0.id == scene.id }
        save()
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(scenes)
            try data.write(to: storeURL, options: .atomic)
        } catch {
            print("Failed to save scenes: \(error)")
        }
    }

    func load() {
        guard let data = try? Data(contentsOf: storeURL) else { return }
        if let decoded = try? JSONDecoder().decode([LightScene].self, from: data) {
            scenes = decoded
        }
    }
}
