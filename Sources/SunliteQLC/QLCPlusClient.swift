import Foundation

/// Статус соединения с WebSocket-интерфейсом QLC+.
enum ConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case failed(String)
}

/// Клиент для управления QLC+ через его встроенный Web/WebSocket API.
///
/// ВАЖНО: протокол ("CH|channel|value" для прямого управления каналом через
/// Simple Desk) основан на документированном поведении QLC+, но я не мог
/// проверить его live (без доступа в сеть к самому QLC+). Перед первым
/// использованием открой Web-интерфейс QLC+ в браузере, подвигай слайдер во
/// Virtual Console с открытым Network/WS инспектором и сравни реальные
/// фреймы с тем, что отправляет этот клиент (см. панель Log в приложении) —
/// если формат отличается, поправь handleIncoming()/setChannel() ниже.
@MainActor
final class QLCPlusClient: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    @Published var status: ConnectionStatus = .disconnected
    @Published var channelValues: [Int: UInt8] = [:]
    @Published var log: [String] = []

    private var session: URLSession!
    private var task: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?

    override init() {
        super.init()
        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    func connect(host: String, port: Int, path: String) {
        disconnect()
        guard let url = URL(string: "ws://\(host):\(port)\(path)") else {
            status = .failed("Некорректный адрес")
            return
        }
        status = .connecting
        appendLog("Подключение к \(url.absoluteString)")
        let newTask = session.webSocketTask(with: url)
        task = newTask
        newTask.resume()
        listen()
    }

    func disconnect() {
        receiveTask?.cancel()
        receiveTask = nil
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        if status != .disconnected {
            status = .disconnected
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        Task { @MainActor in
            self.status = .connected
            self.appendLog("Соединение установлено")
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        Task { @MainActor in
            self.status = .disconnected
            self.appendLog("Соединение закрыто, код \(closeCode.rawValue)")
        }
    }

    private func listen() {
        receiveTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while let currentTask = self.task, !Task.isCancelled {
                do {
                    let message = try await currentTask.receive()
                    switch message {
                    case .string(let text):
                        self.handleIncoming(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self.handleIncoming(text)
                        }
                    @unknown default:
                        break
                    }
                } catch {
                    self.status = .failed(error.localizedDescription)
                    self.appendLog("Ошибка приёма: \(error.localizedDescription)")
                    break
                }
            }
        }
    }

    /// Разбирает входящие кадры вида "CH|<channel>|<value>" (прямое управление
    /// каналом через Simple Desk) или "<widgetID>|<value>" (обновление
    /// виджета Virtual Console). Формат нужно подтвердить на конкретной
    /// версии QLC+ — см. комментарий в начале файла.
    private func handleIncoming(_ text: String) {
        appendLog("<- \(text)")
        let parts = text.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 2 else { return }
        if parts[0] == "CH", parts.count >= 3,
           let channel = Int(parts[1]), let value = UInt8(parts[2]) {
            channelValues[channel] = value
        } else if let widgetID = Int(parts[0]), let value = UInt8(parts[1]) {
            channelValues[widgetID] = value
        }
    }

    /// Устанавливает значение DMX-канала (0-based абсолютный индекс) и шлёт
    /// команду в QLC+.
    func setChannel(_ channel: Int, value: UInt8) {
        channelValues[channel] = value
        send("CH|\(channel)|\(value)")
    }

    /// Отправляет произвольную команду — полезно для ручной отладки протокола.
    func send(_ text: String) {
        guard let task else {
            appendLog("Нет соединения, команда не отправлена: \(text)")
            return
        }
        appendLog("-> \(text)")
        task.send(.string(text)) { [weak self] error in
            guard let error else { return }
            Task { @MainActor in
                self?.appendLog("Ошибка отправки: \(error.localizedDescription)")
            }
        }
    }

    private func appendLog(_ line: String) {
        log.append(line)
        if log.count > 500 {
            log.removeFirst(log.count - 500)
        }
    }
}
