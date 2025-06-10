// MARK: - AlertMenuView.swift
import SwiftUI

struct AlertMenuView: View {
    @EnvironmentObject var stateManager: StateManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                TacticalColors.background.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("SEND TACTICAL ALERT")
                        .font(TacticalFonts.heading)
                        .foregroundColor(TacticalColors.primary)
                        .padding(.top)
                    
                    VStack(spacing: 15) {
                        ForEach(AlertType.allCases, id: \.self) { alertType in
                            AlertButton(alertType: alertType) {
                                stateManager.sendAlert(alertType)
                                dismiss()
                            }
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct AlertButton: View {
    let alertType: AlertType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: alertType.icon)
                    .font(.title)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(alertType.displayName.uppercased())
                        .font(TacticalFonts.body)
                        .fontWeight(.semibold)
                    
                    Text("Tap to send alert to team")
                        .font(TacticalFonts.caption)
                        .foregroundColor(TacticalColors.secondary)
                }
                
                Spacer()
            }
            .foregroundColor(alertType == .danger ? TacticalColors.danger : TacticalColors.warning)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(alertType == .danger ? TacticalColors.danger : TacticalColors.warning, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill((alertType == .danger ? TacticalColors.danger : TacticalColors.warning).opacity(0.1))
                    )
            )
        }
    }
}
//
//  AlertMenuView.swift
//  TacticalMap
//
//  Created by Jaroslavs Krots on 09/06/2025.
//

