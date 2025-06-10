
// MARK: - TacticalButton.swift
import SwiftUI

struct TacticalButton: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void
    
    init(title: String, icon: String? = nil, isSelected: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                }
                Text(title)
                    .font(TacticalFonts.body)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? TacticalColors.background : TacticalColors.primary)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? TacticalColors.primary : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(TacticalColors.primary, lineWidth: 2)
                    )
            )
        }
    }
}

struct TacticalButtonStyle: ButtonStyle {
    var color: Color = TacticalColors.primary
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? .black : color)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.isPressed ? color : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(color, lineWidth: 2)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct TacticalTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(TacticalColors.surface)
            .foregroundColor(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(TacticalColors.primary, lineWidth: 1)
            )
            .font(TacticalFonts.body)
    }
}
