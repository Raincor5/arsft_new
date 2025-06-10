// MARK: - Extensions.swift
import SwiftUI
import Foundation
import Combine
import UIKit

// MARK: - Color Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Date Extensions
extension Date {
    var timeAgoDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - View Extensions
extension View {
    func tacticalGlow(color: Color = TacticalTheme.Colors.primary, radius: CGFloat = 10) -> some View {
        self
            .shadow(color: color.opacity(0.8), radius: radius)
            .shadow(color: color.opacity(0.4), radius: radius * 2)
    }
    
    func tacticalBorder(color: Color = TacticalTheme.Colors.primary, width: CGFloat = 1) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color, lineWidth: width)
        )
    }
}

// MARK: - Double Extensions
extension Double {
    var formattedDistance: String {
        if self < 1000 {
            return String(format: "%.0fm", self)
        } else {
            return String(format: "%.1fkm", self / 1000)
        }
    }
    
    var compassDirection: String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((self + 22.5) / 45.0) & 7
        return directions[index]
    }
}

// MARK: - CLLocationCoordinate2D Extensions
import CoreLocation

extension CLLocationCoordinate2D {
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: latitude, longitude: longitude)
        let to = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return from.distance(from: to)
    }
}

// MARK: - Publisher Extensions
extension Publisher {
    func asyncMap<T>(
        _ transform: @escaping (Output) async -> T
    ) -> Publishers.FlatMap<Future<T, Never>, Self> {
        flatMap { value in
            Future { promise in
                Task {
                    let output = await transform(value)
                    promise(.success(output))
                }
            }
        }
    }
}

// MARK: - Bundle Extensions
extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

// MARK: - Cancellable Storage
private var cancellableStorageKey: UInt8 = 0

extension ObservableObject {
    var cancellables: Set<AnyCancellable> {
        get {
            objc_getAssociatedObject(self, &cancellableStorageKey) as? Set<AnyCancellable> ?? Set<AnyCancellable>()
        }
        set {
            objc_setAssociatedObject(self, &cancellableStorageKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

// MARK: - JSON Encoding/Decoding Helpers
extension JSONEncoder {
    static let tactical: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
}

extension JSONDecoder {
    static let tactical: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}

// MARK: - Haptic Feedback
enum HapticFeedback {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Device Helpers
struct DeviceInfo {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var hasNotch: Bool {
        guard let window = UIApplication.shared.windows.first else { return false }
        return window.safeAreaInsets.top > 20
    }
    
    static var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    static var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
}

// MARK: - Error Handling
enum TacticalError: LocalizedError {
    case connectionFailed(String)
    case authenticationFailed(String)
    case locationPermissionDenied
    case invalidServerURL
    case sessionNotFound
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .locationPermissionDenied:
            return "Location permission denied"
        case .invalidServerURL:
            return "Invalid server URL"
        case .sessionNotFound:
            return "Session not found"
        case .networkUnavailable:
            return "Network unavailable"
        }
    }
}

// MARK: - UserDefaults Keys
extension UserDefaults {
    private enum Keys {
        static let lastCallsign = "lastCallsign"
        static let lastServerURL = "lastServerURL"
        static let preferredMapType = "preferredMapType"
        static let soundEnabled = "soundEnabled"
        static let vibrationEnabled = "vibrationEnabled"
    }
    
    var lastCallsign: String? {
        get { string(forKey: Keys.lastCallsign) }
        set { set(newValue, forKey: Keys.lastCallsign) }
    }
    
    var lastServerURL: String? {
        get { string(forKey: Keys.lastServerURL) }
        set { set(newValue, forKey: Keys.lastServerURL) }
    }
    
    var preferredMapType: Int {
        get { integer(forKey: Keys.preferredMapType) }
        set { set(newValue, forKey: Keys.preferredMapType) }
    }
    
    var soundEnabled: Bool {
        get { bool(forKey: Keys.soundEnabled) }
        set { set(newValue, forKey: Keys.soundEnabled) }
    }
    
    var vibrationEnabled: Bool {
        get { bool(forKey: Keys.vibrationEnabled) }
        set { set(newValue, forKey: Keys.vibrationEnabled) }
    }
}

// MARK: - Debug Helpers
#if DEBUG
extension View {
    func debugBorder(_ color: Color = .red, width: CGFloat = 1) -> some View {
        self.border(color, width: width)
    }
    
    func debugPrint(_ items: Any...) -> some View {
        print(items)
        return self
    }
}

struct DebugLogger {
    static func log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let filename = URL(fileURLWithPath: file).lastPathComponent
        print("[\(filename):\(line)] \(function) - \(message)")
    }
}
#endif

// MARK: - Launch Screen
struct LaunchScreen: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            TacticalColors.background.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "scope")
                    .font(.system(size: 80))
                    .foregroundColor(TacticalColors.primary)
                    .tacticalGlow()
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                Text("TACTICAL")
                    .font(TacticalFonts.title)
                    .foregroundColor(TacticalColors.primary)
                    .tacticalGlow()
                
                Text("AIRSOFT MAP")
                    .font(TacticalFonts.heading)
                    .foregroundColor(TacticalColors.primary.opacity(0.8))
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - App Storage Keys
@propertyWrapper
struct AppStorage<T> {
    let key: String
    let defaultValue: T
    
    var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

// MARK: - Async Button
struct AsyncButton<Label: View>: View {
    var action: () async -> Void
    @ViewBuilder var label: () -> Label
    
    @State private var isPerformingTask = false
    
    var body: some View {
        Button(
            action: {
                isPerformingTask = true
                
                Task {
                    await action()
                    isPerformingTask = false
                }
            },
            label: {
                ZStack {
                    label()
                        .opacity(isPerformingTask ? 0 : 1)
                    
                    if isPerformingTask {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: TacticalColors.primary))
                    }
                }
            }
        )
        .disabled(isPerformingTask)
    }
}

// MARK: - Modifiers
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
                y: 0
            )
        )
    }
}

extension View {
    func shake(amount: CGFloat = 10, shakesPerUnit: Int = 3, animatableData: CGFloat) -> some View {
        modifier(ShakeEffect(amount: amount, shakesPerUnit: shakesPerUnit, animatableData: animatableData))
    }
}
