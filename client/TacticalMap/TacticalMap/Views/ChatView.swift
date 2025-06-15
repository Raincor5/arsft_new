// MARK: - ChatView.swift
import SwiftUI
import Foundation
import Combine
import CoreLocation

struct ChatView: View {
    @EnvironmentObject var stateManager: StateManager
    @State private var messageText = ""
    @State private var showAllChat = false
    @FocusState private var isInputFocused: Bool
    
    var visibleMessages: [Message] {
        stateManager.getVisibleMessages()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                TacticalColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Chat toggle
                    Picker("Chat Visibility", selection: $showAllChat) {
                        Text("TEAM").tag(false)
                        Text("ALL").tag(true)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 10) {
                                ForEach(visibleMessages) { message in
                                    MessageRow(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: visibleMessages.count) { _ in
                            withAnimation {
                                proxy.scrollTo(visibleMessages.last?.id, anchor: .bottom)
                            }
                        }
                    }
                    
                    // Input
                    HStack(spacing: 10) {
                        TextField("Type message...", text: $messageText)
                            .textFieldStyle(TacticalTextFieldStyle())
                            .focused($isInputFocused)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(messageText.isEmpty ?
                                              TacticalColors.secondary : TacticalColors.primary)
                        }
                        .disabled(messageText.isEmpty)
                    }
                    .padding()
                    .background(TacticalColors.surface)
                }
            }
            .navigationTitle("COMMS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        stateManager.sendChatMessage(
            trimmed,
            visibility: showAllChat ? .all : .team
        )
        
        messageText = ""
    }
    
    @Environment(\.dismiss) private var dismiss
}

struct MessageRow: View {
    let message: Message
    @EnvironmentObject var stateManager: StateManager
    
    var isOwnMessage: Bool {
        guard let currentUserId = stateManager.currentPlayer?.id else {
            return false
        }
        return message.senderId == currentUserId
    }
    
    var senderName: String {
        if let player = stateManager.players[message.senderId] {
            return player.callsign
        }
        return "Unknown"
    }
    
    var body: some View {
        VStack(alignment: isOwnMessage ? .trailing : .leading, spacing: 4) {
            // Sender info
            HStack(spacing: 5) {
                if MessageType(rawValue: message.type) == .alert {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(TacticalColors.warning)
                        .font(.caption)
                }
                
                Text(senderName)
                    .font(TacticalFonts.caption)
                    .foregroundColor(isOwnMessage ? TacticalColors.primary : TacticalColors.secondary)
                
                Text("• \(Date(timeIntervalSince1970: message.sentAt), style: .time)")
                    .font(.caption2)
                    .foregroundColor(TacticalColors.secondary.opacity(0.7))
            }
            
            // Message content
            Text(message.content)
                .font(TacticalFonts.body)
                .foregroundColor(.white)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isOwnMessage ?
                              TacticalColors.primary.opacity(0.2) :
                              TacticalColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isOwnMessage ?
                                       TacticalColors.primary :
                                       TacticalColors.secondary.opacity(0.3),
                                       lineWidth: 1)
                        )
                )
        }
        .frame(maxWidth: .infinity, alignment: isOwnMessage ? .trailing : .leading)
    }
}
