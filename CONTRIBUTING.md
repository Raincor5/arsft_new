# Project Rules & Development Guidelines

## General Guidelines

- Follow Swift style guidelines for iOS development
- Follow PEP 8 for Python server code
- Document all functions, classes, and complex logic
- Write unit tests for critical components

## iOS Client Requirements

### Architecture
- Swift-based application
- MVVM architecture recommended
- Core Location for positioning
- MapKit integration for map display

### UI/UX Requirements
- Military-inspired tactical interface
- Color scheme: Green, grey, black
- High contrast for outdoor visibility
- Minimal UI elements for distraction-free operation
- Touch-friendly large buttons for field use

### Required Screens
1. **Server Configuration**
   - QR code scanner
   - Manual server address input option
   - Connection status indicator

2. **Session Setup**
   - Callsign input
   - Session ID input (for clients)
   - Host/Connect mode selection

3. **Map View**
   - Apple Maps integration
   - Player markers with directional indicators
   - Compass overlay
   - Button overlay (Teams, Alerts, Pins, Center, Chat)
   - Session status indicator

4. **Team Management** (Host only)
   - Team creation and assignment
   - Team naming (Alpha, Bravo, etc.)
   - Player management

### Features Implementation
- Real-time position tracking
- Compass using device sensors
- Team-based visibility rules
- Chat system with team filtering
- Persistent connections during app backgrounding

## Server Requirements

### Architecture
- Python-based websocket server
- Authoritative game state management
- Delta-based state synchronization
- Session persistence

### Technical Requirements
- Efficient snapshot/delta broadcasting
- Team-based data segregation
- Real-time synchronization (optimized tick rate)
- Session state persistence
- No automatic player removal on temporary disconnection
- QR code generation for connection

### Security
- Validate all client input
- Implement team-based data access control
- Prevent session/player data leakage between teams

## Performance Guidelines

- Minimize network bandwidth usage
- Optimize battery consumption on mobile devices
- Ensure reliable operation in poor network conditions
- Maintain accurate positioning even with GPS fluctuations 