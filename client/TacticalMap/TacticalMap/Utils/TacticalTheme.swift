import SwiftUI

public enum TacticalTheme {
    public enum Colors {
        public static let primary = Color("AccentColor")
        public static let background = Color.black
        public static let warning = Color.orange
        public static let alphaTeam = Color.blue
        public static let bravoTeam = Color.red
    }
    
    public enum Fonts {
        public static let title = Font.custom("Menlo-Bold", size: 32)
        public static let heading = Font.custom("Menlo", size: 24)
        public static let caption = Font.custom("Menlo", size: 14)
    }
} 