// MARK: - WebSocketService.swift
import Foundation
import Combine
import SwiftUI

// Import local modules
@_exported import struct CoreLocation.CLLocationDistance
@_exported import struct Foundation.TimeInterval

// MARK: - Notifications
extension Notification.Name {
    static let webSocketDidConnect = Notification.Name("webSocketDidConnect")
}

enum ConnectionState {
    case disconnected
    case connecting
    case connected
}

class WebSocketService: NSObject, ObservableObject {
    static let shared = WebSocketService()
    
    @Published var connectionState: ConnectionState = .disconnected
    @Published var lastError: String?
    
    private var webSocket: URLSessionWebSocketTask?
    private var session: URLSession?
    private var pingTimer: Timer?
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    
    private let messageSubject = PassthroughSubject<Data, Never>()
    var messagePublisher: AnyPublisher<Data, Never> {
        messageSubject.eraseToAnyPublisher()
    }
    
    override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    

    func connect(to url: URL) {
        print("WebSocketService: Attempting to connect to \(url.absoluteString)")
        
        // Ensure we're not already connected or connecting
        guard connectionState == .disconnected else {
            print("WebSocketService: Already connected or connecting.")
            return
        }

        connectionState = .connecting
        lastError = nil
        
        webSocket = session?.webSocketTask(with: url)
        webSocket?.resume()
        
        // Start receiving messages
        receiveMessage()
    }
    
    func disconnect() {
        stopPingTimer()
        stopReconnectTimer()
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
        connectionState = .disconnected
    }
    
    func send<T: Encodable>(_ message: T) {
        guard connectionState == .connected,
              let webSocket = webSocket else {
            print("Cannot send message: Not connected")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(message)
            let message = URLSessionWebSocketTask.Message.data(data)
            
            webSocket.send(message) { [weak self] error in
                if let error = error {
                    print("WebSocket send error: \(error)")
                    self?.handleError(error)
                }
            }
        } catch {
            print("Encoding error: \(error)")
        }
    }
    
    // Replace the sendRaw method:
    func sendRaw(_ data: Data) {
        guard let webSocket = webSocket else {
            print("Cannot send message: WebSocket is not initialized.")
            return
        }
        guard connectionState == .connected else {
            print("Cannot send message: WebSocket not connected (state: \(connectionState))")
            return
        }
        
        // Convert Data to String for text message
        guard let jsonString = String(data: data, encoding: .utf8) else {
            print("Failed to convert data to string")
            return
        }
        
        print("WebSocketService: Sending text message: \(jsonString)")
        let message = URLSessionWebSocketTask.Message.string(jsonString) // Changed from .data to .string
        webSocket.send(message) { error in
            if let error = error {
                print("WebSocket send error: \(error)")
            } else {
                print("WebSocketService: Message sent successfully")
            }
        }
    }
    
    func startPingTimer() {
        print("WebSocketService: Starting ping timer")
        stopPingTimer() // Ensure no multiple timers are running
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func sendPing() {
        let pingMessage = ["type": "ping"]
        if let data = try? JSONSerialization.data(withJSONObject: pingMessage) {
            print("WebSocketService: Sending ping")
            webSocket?.send(URLSessionWebSocketTask.Message.data(data)) { [weak self] error in
                if let error = error {
                    print("Ping error: \(error)")
                    self?.handleError(error)
                }
            }
        }
    }
    
    private func attemptReconnection() {
        guard reconnectAttempts < 3 else {
            print("Max reconnection attempts reached")
            return
        }
        
        reconnectAttempts += 1
        connectionState = .connecting
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.reconnect()
        }
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    private func reconnect() {
        guard let url = webSocket?.originalRequest?.url else { return }
        disconnect() // Cleanly disconnect before reconnecting
        connect(to: url)
    }
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received text: \(text)")
                    // The server sends JSON strings, so we should decode them
                    if let data = text.data(using: .utf8) {
                        self?.messageSubject.send(data)
                    }
                case .data(let data):
                    print("Received data: \(data.count) bytes")
                    self?.messageSubject.send(data)
                @unknown default:
                    break
                }
                self?.receiveMessage()
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                self?.handleError(error)
            }
        }
    }
    
    private func handleError(_ error: Error) {
        lastError = error.localizedDescription
        
        if connectionState == .connected {
            connectionState = .disconnected
            lastError = "WebSocket connection lost"
        }
    }
}

// MARK: - URLSessionWebSocketDelegate
extension WebSocketService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocketService: Connection established")
        DispatchQueue.main.async { [weak self] in
            self?.connectionState = .connected
            self?.reconnectAttempts = 0
            // Notify that we're ready to send messages
            NotificationCenter.default.post(name: .webSocketDidConnect, object: nil)
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocketService: Connection closed with code: \(closeCode)")
        DispatchQueue.main.async { [weak self] in
            self?.connectionState = .disconnected
            
            // Don't try to reconnect on normal closure
            if closeCode != .normalClosure && closeCode != .goingAway {
                self?.attemptReconnection()
            }
        }
    }
}
