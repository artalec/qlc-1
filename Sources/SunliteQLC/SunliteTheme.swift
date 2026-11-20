import SwiftUI

/// Цветовая палитра и стили, подобранные под реальный внешний вид
/// Sunlite Suite 2 (светлая металлическая Aero-тема, не тёмная!),
/// на основе описания интерфейса из официальных обучающих видео Nicolaudie.
enum SunliteTheme {
    // Фирменный оранжевый Sunlite/Nicolaudie
    static let accentOrange = Color(red: 0.95, green: 0.44, blue: 0.13) // #F37021

    // Металлический серебристо-серый градиент панелей (Aero-стиль)
    static let panelLight = Color(red: 0.86, green: 0.88, blue: 0.90)
    static let panelMid = Color(red: 0.76, green: 0.79, blue: 0.82)
    static let panelDark = Color(red: 0.63, green: 0.67, blue: 0.71)

    static let ribbonGradient = LinearGradient(
        colors: [panelLight, panelMid],
        startPoint: .top, endPoint: .bottom
    )

    static let canvasBackground = Color(red: 0.93, green: 0.94, blue: 0.95)

    static let textDark = Color(red: 0.15, green: 0.17, blue: 0.19)
    static let textOnDark = Color.white

    // Цвета типов кнопок — подтверждено официальным руководством Sunlite Suite 2:
    // "Scenes (yellow buttons), Switches (red buttons), Cycles (blue buttons)"
    static let sceneYellow = Color(red: 0.98, green: 0.80, blue: 0.14)
    static let switchRed = Color(red: 0.82, green: 0.18, blue: 0.15)
    static let cycleBlue = Color(red: 0.16, green: 0.42, blue: 0.80)

    static func metalButtonGradient(pressed: Bool) -> LinearGradient {
        if pressed {
            return LinearGradient(colors: [panelDark, panelMid], startPoint: .top, endPoint: .bottom)
        }
        return LinearGradient(colors: [panelLight, panelDark], startPoint: .top, endPoint: .bottom)
    }
}
