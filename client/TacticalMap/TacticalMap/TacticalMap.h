#import <Foundation/Foundation.h>

//! Project version number for TacticalMap.
FOUNDATION_EXPORT double TacticalMapVersionNumber;

//! Project version string for TacticalMap.
FOUNDATION_EXPORT const unsigned char TacticalMapVersionString[];

// Expose our models
@import CoreLocation;
@import SwiftUI;

// Models
#import "Models/Position.h"
#import "Models/Marker.h"
#import "Models/Team.h"
#import "Models/Player.h" 