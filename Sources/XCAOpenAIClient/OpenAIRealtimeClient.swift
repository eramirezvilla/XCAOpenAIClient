import Foundation

public class OpenAIRealtimeClient {
    private var webSocketTask: URLSessionWebSocketTask?
    private let apiKey: String
    private let urlSession = URLSession(configuration: .default)
    public var isConnected: Bool = false
    
    public var onMessageReceived: ((String) -> Void)?  // Callback for incoming messages
    public var onError: ((Error) -> Void)?  // Error handling callback
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    /// Establishes a WebSocket connection to OpenAI's Realtime API.
    public func connect() {
        guard !isConnected else { return }
        
        let urlString = "wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")

        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()
        isConnected = true

        receiveMessages()
    }

    /// Disconnects the WebSocket connection gracefully.
    public func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
    }

    /// Sends a message (text or audio as Base64) to OpenAI.
    public func sendMessage(_ message: String) {
        guard isConnected, let webSocketTask = webSocketTask else { return }
        
        let wsMessage = URLSessionWebSocketTask.Message.string(message)
        webSocketTask.send(wsMessage) { error in
            if let error = error {
                self.onError?(error)
            }
        }
    }

    /// Listens for incoming messages from OpenAI.
    private func receiveMessages() {
        guard let webSocketTask = webSocketTask else { return }

        webSocketTask.receive { [weak self] result in
            switch result {
            case .failure(let error):
                self?.onError?(error)
                self?.isConnected = false
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.onMessageReceived?(text)
                case .data(let data):
                    let text = String(decoding: data, as: UTF8.self)
                    self?.onMessageReceived?(text)
                @unknown default:
                    break
                }
                self?.receiveMessages()  // Continue listening for messages
            }
        }
    }
}