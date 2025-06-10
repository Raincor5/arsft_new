// MARK: - MarkerCreationView.swift
import SwiftUI

struct MarkerCreationView: View {
    @EnvironmentObject var stateManager: StateManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var markerLabel = ""
    @State private var markerDescription = ""
    @State private var markerType: Marker.MarkerType = .pin
    @State private var visibility: Message.Visibility = .team
    
    var body: some View {
        NavigationView {
            ZStack {
                TacticalColors.background.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Label
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MARKER LABEL")
                            .font(TacticalFonts.caption)
                            .foregroundColor(TacticalColors.primary)
                        
                        TextField("Enter label", text: $markerLabel)
                            .textFieldStyle(TacticalTextFieldStyle())
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DESCRIPTION (OPTIONAL)")
                            .font(TacticalFonts.caption)
                            .foregroundColor(TacticalColors.primary)
                        
                        TextField("Enter description", text: $markerDescription)
                            .textFieldStyle(TacticalTextFieldStyle())
                    }
                    
                    // Visibility
                    VStack(alignment: .leading, spacing: 8) {
                        Text("VISIBILITY")
                            .font(TacticalFonts.caption)
                            .foregroundColor(TacticalColors.primary)
                        
                        Picker("Visibility", selection: $visibility) {
                            Text("TEAM ONLY").tag(Message.Visibility.team)
                            Text("ALL TEAMS").tag(Message.Visibility.all)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    Spacer()
                    
                    // Create button
                    Button(action: createMarker) {
                        Text("CREATE MARKER")
                            .font(TacticalFonts.heading)
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .buttonStyle(TacticalButtonStyle())
                    .disabled(markerLabel.isEmpty)
                }
                .padding()
            }
            .navigationTitle("NEW MARKER")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
    private func createMarker() {
        stateManager.createMarker(
            type: markerType,
            label: markerLabel,
            description: markerDescription.isEmpty ? nil : markerDescription,
            visibility: visibility
        )
        dismiss()
    }
}
//
//  MarkerCreationView.swift
//  TacticalMap
//
//  Created by Jaroslavs Krots on 09/06/2025.
//

