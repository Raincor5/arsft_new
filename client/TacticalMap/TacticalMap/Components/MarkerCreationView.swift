// MARK: - MarkerCreationView.swift
import SwiftUI
import CoreLocation

struct MarkerCreationView: View {
    @EnvironmentObject var stateManager: StateManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var markerLabel = ""
    @State private var markerDescription = ""
    @State private var markerType: MarkerType = .waypoint
    @State private var visibility: Visibility = .team
    
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
                    
                    // Marker Type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MARKER TYPE")
                            .font(TacticalFonts.caption)
                            .foregroundColor(TacticalColors.primary)
                        
                        Picker("Marker Type", selection: $markerType) {
                            ForEach(MarkerType.allCases, id: \.self) { type in
                                Text(type.rawValue.uppercased()).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Visibility
                    VStack(alignment: .leading, spacing: 8) {
                        Text("VISIBILITY")
                            .font(TacticalFonts.caption)
                            .foregroundColor(TacticalColors.primary)
                        
                        Picker("Visibility", selection: $visibility) {
                            Text("TEAM ONLY").tag(Visibility.team)
                            Text("ALL TEAMS").tag(Visibility.all)
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

