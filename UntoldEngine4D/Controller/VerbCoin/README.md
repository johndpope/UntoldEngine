# Verb Coin System Documentation

## Overview

The Verb Coin System implements a contextual radial menu interface inspired by adventure games like The Curse of Monkey Island. It provides an intuitive way for players to interact with game objects using icon-based verbs (actions) that appear when long-pressing or right-clicking on interactive elements.

## Architecture

The system consists of four main components:

### 1. U4DVerbCoinManager (Singleton)
- **Location**: `U4DVerbCoinManager.h/.mm`
- **Purpose**: Central coordinator for the verb coin system
- **Responsibilities**:
  - Managing the active verb coin instance
  - Handling long-press detection for touch devices
  - Coordinating input routing to verb coins
  - Managing entity-verb associations
  - Providing global access to verb coin functionality

### 2. U4DVerbCoin (UI Component)
- **Location**: `U4DVerbCoin.h/.mm`
- **Purpose**: The radial menu that displays available verbs
- **Features**:
  - Radial icon arrangement around a central point
  - Smooth fade-in/fade-out animations
  - Touch/hover detection for icon selection
  - Configurable radius and display duration
  - State machine for different interaction states

### 3. U4DVerbIcon (UI Element)
- **Location**: `U4DVerbIcon.h/.mm`
- **Purpose**: Individual verb icons within the radial menu
- **Features**:
  - Hover/pressed state animations with scale effects
  - Tooltip display on hover
  - Texture loading for custom verb icons
  - Hit detection for touch/click events
  - Callback execution for verb actions

### 4. U4DInteractiveEntity (Base Class)
- **Location**: `U4DInteractiveEntity.h/.mm`
- **Purpose**: Base class for objects that support verb coin interactions
- **Features**:
  - Verb registration and management
  - Default action fallbacks
  - Entity naming and description
  - Integration with VerbCoinManager
  - Helper methods for common verbs

## Usage Guide

### Setting Up Interactive Objects

```cpp
// Create an interactive entity
U4DInteractiveEntity* chest = new U4DInteractiveEntity();
chest->setEntityName("treasure_chest");
chest->setDescription("A mysterious treasure chest");
chest->loadTexture("chest.png");
chest->translateTo(U4DVector3n(-0.3, 0.2, 0));

// Add verbs with callbacks
U4DCallback<GameController>* examineCallback = new U4DCallback<GameController>;
examineCallback->scheduleClassWithMethod(this, &GameController::examineChest);
chest->addDefaultExamineVerb(examineCallback);

U4DCallback<GameController>* useCallback = new U4DCallback<GameController>;
useCallback->scheduleClassWithMethod(this, &GameController::openChest);
chest->addDefaultUseVerb(useCallback);

// Add to scene
gameWorld->addChild(chest);
```

### Custom Verbs

```cpp
// Adding a custom verb
VerbData customVerb(eVerbCustom, "dance_icon.png", "Dance with", danceCallback);
interactiveEntity->addVerb(eVerbCustom, "dance_icon.png", "Dance with", danceCallback);
```

### Integration with Input System

The system automatically integrates with the existing U4DTouchesController:

```cpp
// In U4DTouchesController constructor
verbCoinManager = U4DVerbCoinManager::sharedInstance();

// Touch events are automatically routed to verb coin manager first
void U4DTouchesController::touchBegan(const U4DTouches &touches) {
    verbCoinManager->touchBegan(nonConstTouches);
    
    if (verbCoinManager->isVerbCoinVisible()) {
        return; // Verb coin handles the input
    }
    
    // Continue with normal touch processing...
}
```

## Configuration Options

### VerbCoinManager Settings

```cpp
U4DVerbCoinManager* manager = U4DVerbCoinManager::sharedInstance();

// Configure long press duration (default: 0.5 seconds)
manager->setLongPressDuration(0.75f);

// Set global verb callback for all verb actions
manager->setGlobalVerbCallback(globalCallback);
```

### VerbCoin Appearance

```cpp
U4DVerbCoin* verbCoin = manager->getActiveVerbCoin();

// Configure radius (default: 100px)
verbCoin->setRadius(120.0f);

// Configure display duration (default: 3 seconds)
verbCoin->setShowDuration(5.0f);
```

### VerbIcon Customization

```cpp
U4DVerbIcon* icon = // ... get icon reference
icon->setHoverScale(1.3f);      // Scale when hovered (default: 1.2f)
icon->setNormalScale(1.0f);     // Normal scale (default: 1.0f)
```

## Verb Types

The system provides standard verb types defined in `U4DVerbCoin.h`:

```cpp
typedef enum{
    eVerbExamine,    // "Look at" - eye icon
    eVerbUse,        // "Use/Open" - hand icon
    eVerbTalk,       // "Talk to" - mouth icon
    eVerbPickUp,     // "Pick up" - pickup icon
    eVerbCombine,    // "Combine with" - combine icon
    eVerbCustom      // Custom verbs
} VERBTYPE;
```

## State Management

### VerbCoin States
- `eVerbCoinIdle`: Not displayed
- `eVerbCoinShowing`: Visible and accepting input
- `eVerbCoinHidden`: Animating out or invisible
- `eVerbCoinHovering`: User is hovering over an icon

### VerbIcon States
- `eVerbIconIdle`: Normal state
- `eVerbIconHovered`: Mouse/touch over icon
- `eVerbIconPressed`: Icon is being pressed
- `eVerbIconSelected`: Icon has been selected

## Touch Input Flow

1. **Long Press Detection**: User starts touching screen
2. **Timer Activation**: VerbCoinManager starts long press timer
3. **Threshold Reached**: After configured duration, verb coin appears
4. **Icon Selection**: User moves finger/cursor over desired verb icon
5. **Action Execution**: User releases touch to execute verb action
6. **Cleanup**: Verb coin disappears and normal input resumes

## Example Implementation

The `GameController` class in the demo shows a complete implementation:

```cpp
// In GameController::setupInteractiveObjects()
interactiveChest = new U4DInteractiveEntity();
interactiveChest->setEntityName("treasure_chest");
interactiveChest->addDefaultExamineVerb(examineCallback);
interactiveChest->addDefaultUseVerb(openCallback);
interactiveChest->addDefaultPickUpVerb(pickupCallback);
earth->addChild(interactiveChest, -5);

// Verb action implementations
void GameController::examineChest() {
    // Display descriptive text about the chest
    // Could integrate with dialogue system, UI text display, etc.
}

void GameController::openChest() {
    // Play opening animation, reveal contents
    // Could integrate with inventory system, particle effects, etc.
}
```

## Performance Considerations

- **Memory**: Each interactive entity stores its verb list, minimal overhead
- **Rendering**: Verb icons are only created when needed, cleaned up automatically
- **Input**: Touch processing is optimized to avoid unnecessary entity searches
- **Frame Rate**: System maintains 60 FPS during menu interactions

## Troubleshooting

### Common Issues

1. **Verb coin not appearing**: 
   - Check that entity has registered verbs
   - Verify long press duration is appropriate
   - Ensure entity is marked as interactable

2. **Icons not displaying**:
   - Verify texture file paths are correct
   - Check that textures are in Resources directory
   - Ensure proper Metal renderer setup

3. **Touch detection issues**:
   - Confirm hit detection boundaries are correct
   - Verify screen coordinate conversion
   - Check for overlapping UI elements

### Debug Methods

```cpp
// Check if entity has verbs registered
if (entity->getAvailableVerbs().empty()) {
    // Entity has no verbs - add some!
}

// Verify manager state
U4DVerbCoinManager* manager = U4DVerbCoinManager::sharedInstance();
if (!manager->isVerbCoinVisible()) {
    // Verb coin should be visible but isn't
}

// Check entity registration
manager->registerEntityVerbs(entity, verbs);
```

## Future Enhancements

Potential improvements for future versions:

1. **Sound Integration**: Audio cues for verb coin appearance and selection
2. **Animation Polish**: More sophisticated entrance/exit animations
3. **Accessibility**: Screen reader support, high contrast modes
4. **Customization**: User-configurable verb layouts and appearances
5. **Inventory Integration**: Drag-and-drop item-to-entity interactions
6. **Localization**: Multi-language support for verb tooltips

## File Structure

```
UntoldEngine4D/Controller/VerbCoin/
├── U4DVerbCoinManager.h/.mm      # Singleton coordinator
├── U4DVerbCoin.h/.mm             # Radial menu component
├── U4DVerbIcon.h/.mm             # Individual verb icons
├── U4DInteractiveEntity.h/.mm    # Interactive object base class
└── README.md                     # This documentation

Game/
├── GameController.h/.mm          # Example implementation
```

## Dependencies

- U4DVisibleEntity (base rendering)
- U4DImage (texture loading)
- U4DText (tooltip display)
- U4DTouchesController (input integration)
- U4DCallback (action callbacks)
- U4DDirector (screen dimensions)

This system provides a complete, production-ready implementation of contextual verb-based interaction for adventure games within the Untold Engine framework.