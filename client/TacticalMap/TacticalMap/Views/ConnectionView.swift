// MARK: - ConnectionView.swift
import SwiftUI
import AVFoundation
import Combine

struct ConnectionView: View {
    @Binding var isConnected: Bool
    @EnvironmentObject var stateManager: StateManager
    
    @State private var serverAddress = "ws://localhost:8765"
    @State private var joinServerAddress = "ws://localhost:8765"  // Separate address for join mode
    @State private var sessionId = ""
    @State private var callsign = ""
    @State private var isHost = false
    @State private var showQRScanner = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isConnecting = false
    
    @StateObject private var locationService = LocationService.shared
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                // Scan lines effect
                GeometryReader { geometry in
                    let lineCount = 5
                    let lineSpacing = geometry.size.height / CGFloat(lineCount)
                    
                    ForEach(0..<lineCount, id: \.self) { index in
                        let yOffset = CGFloat(index) * lineSpacing
                        let animationDelay = Double(index) * 0.5
                        
                        Rectangle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(height: 1)
                            .offset(y: yOffset)
                            .animation(
                                Animation.linear(duration: 3)
                                    .repeatForever(autoreverses: false)
                                    .delay(animationDelay),
                                value: index
                            )
                    }
                }
                .opacity(0.3)
                
                // Content
                VStack(spacing: 30) {
                    // Title
                    VStack(spacing: 10) {
                        Text("TACTICAL")
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.blue)
                            .shadow(color: .blue, radius: 10)
                        
                        Text("AIRSOFT MAP")
                            .font(.system(size: 24, weight: .medium, design: .monospaced))
                            .foregroundColor(.blue.opacity(0.8))
                            .shadow(color: .blue, radius: 5)
                    }
                    .padding(.top, 50)
                    
                    Spacer()
                    
                    // Connection Options
                    VStack(spacing: 20) {
                        // Mode Selection
                        HStack(spacing: 20) {
                            TacticalButton(
                                title: "HOST",
                                icon: "server.rack",
                                isSelected: isHost,
                                action: { isHost = true }
                            )
                            
                            TacticalButton(
                                title: "JOIN",
                                icon: "link",
                                isSelected: !isHost,
                                action: { isHost = false }
                            )
                        }
                        .padding(.horizontal)
                        
                        // Callsign Input
                        VStack(alignment: .leading, spacing: 5) {
                            Text("CALLSIGN")
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundColor(.blue)
                            
                            TextField("Enter your callsign", text: $callsign)
                                .textFieldStyle(TacticalTextFieldStyle())
                                .autocapitalization(.allCharacters)
                        }
                        .padding(.horizontal)
                        
                        // Server/Session Input
                        if isHost {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("SERVER ADDRESS")
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(.blue)
                                
                                TextField("ws://server:port", text: $serverAddress)
                                    .textFieldStyle(TacticalTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                            .padding(.horizontal)
                        } else {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("SERVER ADDRESS")
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(.blue)
                                
                                TextField("ws://server:port", text: $joinServerAddress)
                                    .textFieldStyle(TacticalTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                
                                Text("SESSION ID")
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(.blue)
                                
                                HStack {
                                    TextField("Enter session ID", text: $sessionId)
                                        .textFieldStyle(TacticalTextFieldStyle())
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                    
                                    Button(action: { showQRScanner = true }) {
                                        Image(systemName: "qrcode.viewfinder")
                                            .font(.title2)
                                            .foregroundColor(.blue)
                                            .padding(10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.blue, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Connect Button
                        Button(action: connect) {
                            if isConnecting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity, minHeight: 50)
                            } else {
                                Text(isHost ? "CREATE SESSION" : "JOIN SESSION")
                                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, minHeight: 50)
                            }
                        }
                        .buttonStyle(TacticalButtonStyle())
                        .disabled(callsign.isEmpty || isConnecting)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Location Permission Status
                    if locationService.authorizationStatus != .authorizedAlways &&
                       locationService.authorizationStatus != .authorizedWhenInUse {
                        VStack(spacing: 10) {
                            Image(systemName: "location.slash")
                                .font(.title)
                                .foregroundColor(.orange)
                            
                            Text("Location access required")
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundColor(.orange)
                            
                            Button("Enable Location") {
                                locationService.requestAuthorization()
                            }
                            .buttonStyle(TacticalButtonStyle(color: .orange))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.orange, lineWidth: 1)
                                .background(Color.orange.opacity(0.1))
                        )
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showQRScanner) {
                QRScannerView(scannedCode: $sessionId)
            }
            .alert("Connection Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func connect() {
        guard !callsign.isEmpty else { return }
        
        isConnecting = true
        errorMessage = ""
        
        // Parse server URL
        let serverURL: String
        if isHost {
            serverURL = serverAddress
        } else {
            if let qrURL = parseQRCode(sessionId) {
                serverURL = qrURL
            } else {
                serverURL = joinServerAddress
            }
        }
        
        guard let url = URL(string: serverURL) else {
            errorMessage = "Invalid server URL"
            showError = true
            isConnecting = false
            return
        }
        
        print("Connecting to server at: \(url.absoluteString)")
        
        // Connect
        stateManager.connect(
            to: url,
            sessionId: isHost ? nil : sessionId,
            isHost: isHost,
            callsign: callsign
        )
        
        // Monitor connection state
        WebSocketService.shared.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { state in
                switch state {
                case .connected:
                    self.isConnected = true
                    self.isConnecting = false
                case .disconnected:
                    if self.isConnecting {
                        self.errorMessage = "Failed to connect to server"
                        self.showError = true
                        self.isConnecting = false
                    }
                case .connecting:
                    // Keep isConnecting true while connecting
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    private func parseQRCode(_ code: String) -> String? {
        // Expected format: tacticalairsoft://host:port/sessionId
        if code.starts(with: "tacticalairsoft://") {
            let components = code.dropFirst("tacticalairsoft://".count).split(separator: "/")
            if components.count >= 2 {
                sessionId = String(components[1])
                return "ws://\(components[0])"
            }
        }
        return nil
    }
}
