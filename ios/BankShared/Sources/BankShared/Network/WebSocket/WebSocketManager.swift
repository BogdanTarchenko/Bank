import Foundation

public final class WebSocketManager: @unchecked Sendable {
    private var webSocketTask: URLSessionWebSocketTask?
    private let session = URLSession.shared
    private var isConnected = false
    private var onMessage: (@Sendable (Operation) -> Void)?
    private let decoder = JSONDecoder()

    public init() {}

    public func connect(baseURL: String, token: String?, onMessage: @escaping @Sendable (Operation) -> Void) {
        self.onMessage = onMessage

        // SockJS raw WebSocket fallback endpoint
        let wsURL = baseURL
            .replacingOccurrences(of: "http://", with: "ws://")
            .replacingOccurrences(of: "https://", with: "wss://")
        guard let url = URL(string: "\(wsURL)/ws/operations/websocket") else { return }

        var request = URLRequest(url: url)
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()

        // Send STOMP CONNECT
        let connectFrame = STOMPFrame.connect()
        send(connectFrame)

        receiveMessages()
    }

    public func subscribe(destination: String) {
        let frame = STOMPFrame.subscribe(destination: destination)
        send(frame)
    }

    public func disconnect() {
        let frame = STOMPFrame.disconnect()
        send(frame)
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
    }

    private func send(_ frame: STOMPFrame) {
        let message = URLSessionWebSocketTask.Message.string(frame.serialize())
        webSocketTask?.send(message) { _ in }
    }

    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleFrame(text)
                default:
                    break
                }
                self.receiveMessages()
            case .failure:
                self.isConnected = false
            }
        }
    }

    private func handleFrame(_ text: String) {
        guard let frame = STOMPFrame.parse(text) else { return }

        switch frame.command {
        case .CONNECTED:
            isConnected = true
        case .MESSAGE:
            if let body = frame.body, let data = body.data(using: .utf8) {
                if let operation = try? decoder.decode(Operation.self, from: data) {
                    onMessage?(operation)
                }
            }
        default:
            break
        }
    }
}
