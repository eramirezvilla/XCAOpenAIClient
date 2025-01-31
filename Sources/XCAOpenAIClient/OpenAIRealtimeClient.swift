import Foundation

public struct OpenAIRealtimeClient {
    private var webSocketTask: URLSessionWebSocketTask?
    private let apiKey: String
    private let urlSession = URLSession(configuration: .default)

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func connect() {
        var request = URLRequest(url: URL(string: "wss://api.openai.com/v1/realtime")!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")
        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()
        receiveMessages()
    }

    public func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }

    public func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("Error receiving message: \(error)")
            case .success(let message):
                switch message {
                case .data(let data):
                    self?.handleData(data)
                case .string(let text):
                    self?.handleText(text)
                @unknown default:
                    break
                }
                self?.receiveMessages()
            }
        }
    }

    public func handleData(_ data: Data) {
        // Handle received data
    }

    public func handleText(_ text: String) {
        // Handle received text
    }

    public func sendMessage(_ message: String) {
        let message = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("Error sending message: \(error)")
            }
        }
    }
}