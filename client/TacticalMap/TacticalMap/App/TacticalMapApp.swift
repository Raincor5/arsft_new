// MARK: - TacticalAirsoftMapApp.swift
import SwiftUI

@main
struct TacticalAirsoftMapApp: App {
    @StateObject private var stateManager = StateManager.shared
    @State private var isConnected = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isConnected {
                    MapView()
                        .environmentObject(stateManager)
                        .preferredColorScheme(.dark)
                } else {
                    ConnectionView(isConnected: $isConnected)
                        .environmentObject(stateManager)
                        .preferredColorScheme(.dark)
                }
            }
            .onAppear {
                setupAppearance()
            }
        }
    }
    
    private func setupAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.systemGreen]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.systemGreen]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure tab bar
        UITabBar.appearance().backgroundColor = UIColor.black
        UITabBar.appearance().tintColor = UIColor.systemGreen
    }
}
