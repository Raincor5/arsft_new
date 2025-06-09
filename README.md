# Tactical Airsoft Map

A real-time tactical map application for iOS designed for airsoft games, featuring live position tracking, team coordination, and tactical communication.

## Overview

This project consists of two main components:
- **iOS Client**: Built with Swift, providing a game-like tactical map interface
- **Python Server**: An authoritative websocket server that manages game state and real-time synchronization

## Features

### Connection & Setup
- QR code scanning for server configuration
- Host or Connect options with session management
- Callsign (nickname) configuration

### Map Interface
- Apple Maps integration for real-world positioning
- Real-time player position tracking with directional indicators
- Team-based information sharing (no data exposed to enemy teams)
- Compass utilizing iPhone sensors
- Location-based tactical alerts

### Communication
- Team-based chat system
- Quick alert system for tactical notifications
- Session management with player status

### Server Architecture
- Authoritative game server with snapshots/deltas
- Real-time synchronization with optimized tick rate
- Session persistence (maintains connections during screen lock)
- Team-based data segregation for tactical advantage

## UI/UX

The application features a modern warfare theme with tactical aesthetics:
- Color scheme: Green, grey, and black
- Military-style team designations (Alpha, Bravo, etc.)
- Game-like interface elements optimized for field use

## Technical Requirements

- iOS device with location services
- Server with Python support
- Internet connectivity for all participants 