# Tactical Airsoft Map - Data Schema

## Server-Side Data Models

### Session
```json
{
  "session_id": "string (uuid)",
  "created_at": "timestamp",
  "last_active": "timestamp",
  "host_id": "string (player_id)",
  "teams": ["team_id"],
  "settings": {
    "map_bounds": {
      "north": "float",
      "south": "float",
      "east": "float",
      "west": "float"
    },
    "update_frequency": "int (Hz)",
    "session_name": "string",
    "allow_join": "boolean"
  }
}
```

### Player
```json
{
  "player_id": "string (uuid)",
  "callsign": "string",
  "team_id": "string",
  "connection_status": "enum (connected, disconnected, inactive)",
  "last_active": "timestamp",
  "position": {
    "latitude": "float",
    "longitude": "float",
    "heading": "float (degrees)",
    "accuracy": "float (meters)",
    "elevation": "float (meters)",
    "updated_at": "timestamp"
  },
  "device_info": {
    "device_type": "string",
    "os_version": "string",
    "app_version": "string"
  }
}
```

### Team
```json
{
  "team_id": "string (uuid)",
  "name": "string",
  "color": "string (hex)",
  "players": ["player_id"],
  "markers": ["marker_id"]
}
```

### Marker
```json
{
  "marker_id": "string (uuid)",
  "type": "enum (pin, area, line)",
  "created_by": "string (player_id)",
  "team_id": "string",
  "visibility": "enum (team, all)",
  "position": {
    "latitude": "float",
    "longitude": "float"
  },
  "properties": {
    "label": "string",
    "description": "string",
    "icon": "string",
    "color": "string (hex)"
  },
  "created_at": "timestamp",
  "expires_at": "timestamp (optional)"
}
```

### Message
```json
{
  "message_id": "string (uuid)",
  "sender_id": "string (player_id)",
  "team_id": "string",
  "visibility": "enum (team, all)",
  "type": "enum (chat, alert, system)",
  "content": "string",
  "sent_at": "timestamp",
  "location": {
    "latitude": "float (optional)",
    "longitude": "float (optional)"
  }
}
```

## State Delta Format

```json
{
  "delta_id": "string (uuid)",
  "session_id": "string",
  "timestamp": "timestamp",
  "sequence_number": "int",
  "changes": [
    {
      "type": "enum (add, update, remove)",
      "entity_type": "enum (player, marker, message, team)",
      "entity_id": "string",
      "data": "object (partial or complete entity data)",
      "path": "string (optional, JSON path for nested updates)"
    }
  ]
}
```

## Client-Server Messages

### Authentication Request
```json
{
  "type": "auth",
  "callsign": "string",
  "session_id": "string",
  "is_host": "boolean",
  "device_info": {
    "device_type": "string",
    "os_version": "string",
    "app_version": "string"
  }
}
```

### Authentication Response
```json
{
  "type": "auth_response",
  "success": "boolean",
  "player_id": "string",
  "team_id": "string",
  "session_state": "object (full initial state)",
  "error": "string (optional)"
}
```

### Position Update
```json
{
  "type": "position_update",
  "player_id": "string",
  "latitude": "float",
  "longitude": "float",
  "heading": "float",
  "accuracy": "float",
  "elevation": "float",
  "timestamp": "timestamp"
}
```

### Delta Broadcast
```json
{
  "type": "state_delta",
  "delta": "object (state delta format)"
}
```

### Full State Snapshot
```json
{
  "type": "state_snapshot",
  "sequence_number": "int",
  "timestamp": "timestamp",
  "state": "object (full state)"
}
```

### Chat Message
```json
{
  "type": "chat",
  "content": "string",
  "visibility": "enum (team, all)",
  "location": {
    "latitude": "float (optional)",
    "longitude": "float (optional)"
  }
}
```

### Alert Message
```json
{
  "type": "alert",
  "alert_type": "enum (contact, danger, rally, help)",
  "location": {
    "latitude": "float",
    "longitude": "float"
  }
}
```

### Create/Update Marker
```json
{
  "type": "marker",
  "action": "enum (create, update, delete)",
  "marker_id": "string (optional for create)",
  "marker_data": "object (marker properties)"
}
``` 