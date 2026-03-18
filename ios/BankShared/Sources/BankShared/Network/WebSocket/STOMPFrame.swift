import Foundation

public enum STOMPCommand: String, Sendable {
    case CONNECT, CONNECTED, SUBSCRIBE, UNSUBSCRIBE, SEND, MESSAGE, DISCONNECT, ERROR
}

public struct STOMPFrame: Sendable {
    public let command: STOMPCommand
    public let headers: [String: String]
    public let body: String?

    public init(command: STOMPCommand, headers: [String: String] = [:], body: String? = nil) {
        self.command = command
        self.headers = headers
        self.body = body
    }

    public func serialize() -> String {
        var result = command.rawValue + "\n"
        for (key, value) in headers {
            result += "\(key):\(value)\n"
        }
        result += "\n"
        if let body {
            result += body
        }
        result += "\0"
        return result
    }

    public static func parse(_ text: String) -> STOMPFrame? {
        let cleaned = text.replacingOccurrences(of: "\0", with: "")
        let parts = cleaned.split(separator: "\n\n", maxSplits: 1).map(String.init)
        guard !parts.isEmpty else { return nil }

        let headerLines = parts[0].split(separator: "\n").map(String.init)
        guard let commandStr = headerLines.first,
              let command = STOMPCommand(rawValue: commandStr) else { return nil }

        var headers: [String: String] = [:]
        for line in headerLines.dropFirst() {
            let kv = line.split(separator: ":", maxSplits: 1).map(String.init)
            if kv.count == 2 {
                headers[kv[0]] = kv[1]
            }
        }

        let body = parts.count > 1 ? parts[1] : nil
        return STOMPFrame(command: command, headers: headers, body: body)
    }

    public static func connect() -> STOMPFrame {
        STOMPFrame(command: .CONNECT, headers: ["accept-version": "1.2", "heart-beat": "0,0"])
    }

    public static func subscribe(destination: String, id: String = "sub-0") -> STOMPFrame {
        STOMPFrame(command: .SUBSCRIBE, headers: ["id": id, "destination": destination])
    }

    public static func disconnect() -> STOMPFrame {
        STOMPFrame(command: .DISCONNECT)
    }
}
