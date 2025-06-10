    private func authenticate(callsign: String) {
        let deviceInfo = Player.DeviceInfo(
            deviceType: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        )
        
        var authMessage: [String: Any] = [
            "type": "auth",
            "callsign": callsign,
            "is_host": isHost,
            "device_info": [
                "device_type": deviceInfo.deviceType,
                "os_version": deviceInfo.osVersion,
                "app_version": deviceInfo.appVersion
            ]
        ]
        
        // Only include session_id when joining
        if !isHost, let sessionId = sessionId {
            authMessage["session_id"] = sessionId
        }
        
        if let data = try? JSONSerialization.data(withJSONObject: authMessage) {
            print("Sending auth message: \(String(data: data, encoding: .utf8) ?? "")")
            webSocketService.sendRaw(data)
        }
    } 