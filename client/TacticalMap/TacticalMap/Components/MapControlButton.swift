//
//  MapControlButton.swift
//  TacticalMap
//
//  Created by Jaroslavs Krots on 09/06/2025.
//

import SwiftUICore
import SwiftUI

// MARK: - MapControlButton.swift
struct MapControlButton: View {
    let icon: String
    let label: String
    var color: Color = TacticalColors.primary
    var badge: Int = 0
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                    
                    if badge > 0 {
                        Text("\(badge)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(3)
                            .background(Circle().fill(TacticalColors.danger))
                            .offset(x: 8, y: -8)
                    }
                }
                
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(color)
            }
            .frame(width: 60, height: 60)
        }
    }
}
