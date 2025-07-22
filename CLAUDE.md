# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

The Untold Engine is an open-source 3D game engine written in C++ and Metal Graphics API, developed specifically for Apple platforms (iOS, macOS, tvOS). It's designed as an educational resource to help developers understand game engine architecture and development patterns.

**Important**: This engine is in beta (v0.0.10) and is licensed under LGPL v2.1. The primary purpose is educational - to demonstrate how game engines work.

## Building and Development

### Requirements
- Xcode IDE (macOS development environment)
- Apple Developer Account (for device testing)
- iOS device and Mac with Metal API support
- Target platforms: iOS, macOS, tvOS

### Build System
- Uses Xcode project format (.xcodeproj)
- Multi-target setup for iOS, macOS, and tvOS
- Shared codebase between platforms with platform-specific entry points
- Metal shaders compilation integrated into build process

### Development Commands
```bash
# Open the project
open UntoldEngine.xcodeproj

# Build for iOS (Xcode command line)
xcodebuild -project UntoldEngine.xcodeproj -scheme "Untold4D iOS" -configuration Debug

# Build for macOS
xcodebuild -project UntoldEngine.xcodeproj -scheme "Untold4D macOS" -configuration Debug

# Build for tvOS
xcodebuild -project UntoldEngine.xcodeproj -scheme "Untold4D tvOS" -configuration Debug
```

## Code Architecture

### Core Design Patterns
- **Singleton**: U4DDirector manages engine lifecycle and coordination
- **Entity-Component-System**: Flexible game object composition
- **Model-View-Controller**: Clean separation of game logic, rendering, and input
- **State Machine**: Input controllers and animation systems
- **Strategy**: Pluggable physics integration and collision detection algorithms

### Main Subsystems

#### 1. Director System (UntoldEngine4D/Director/)
Central engine controller that manages:
- Game loop and update cycles
- Input event coordination across all platforms
- Rendering pipeline orchestration
- Scene management and transitions
- Metal graphics context management

#### 2. Entity Hierarchy (UntoldEngine4D/Objects/)
```
U4DEntity (base transformation and scenegraph)
├── U4DVisibleEntity (adds rendering capabilities)
    ├── U4DWorld (scene root container)
    ├── U4DModel (3D geometry and materials)
        ├── U4DStaticModel (non-physics objects)
        └── U4DDynamicModel (physics-enabled objects)
            └── U4DGameObject (character controllers)
    ├── U4DImage/U4DSprite (2D graphics)
    ├── U4DText (font rendering)
    └── U4DParticleSystem (particle effects)
```

#### 3. Rendering Pipeline (UntoldEngine4D/RenderEngine/)
- **U4DRenderManager**: Base class for all Metal rendering operations
- Specialized renderers for different entity types (3D models, fonts, images, particles, sprites, skybox)
- Metal shader integration in MetalShaders/ directory
- Supports shadow mapping, lighting, and post-processing effects

#### 4. Physics Engine (UntoldEngine4D/PhysicsEngine/)
- **U4DPhysicsEngine**: Coordinates force generation and integration
- **Collision Detection**: Two-phase system with BVH broad-phase and GJK/EPA narrow-phase
- **Force Generators**: Gravity, drag, and resting forces
- **Integration**: Runge-Kutta method for numerical physics simulation
- **Collision Response**: Manifold generation and resolution

#### 5. Controller System (UntoldEngine4D/Controller/)
Multi-platform input handling:
- **iOS Touch**: U4DTouchesController for touch input
- **macOS Mouse/Keyboard**: U4DMacMouse, U4DMacKey, U4DMacArrowKey controllers  
- **Gamepad**: U4DGamepadController for external game controllers
- **UI Components**: State-based buttons (U4DButton) and joysticks (U4DJoyStick)

#### 6. Animation System (UntoldEngine4D/Animation/)
- **U4DAnimationManager**: Handles keyframe animation playback
- **U4DBlendAnimation**: Smooth transitions between animations
- Skeletal animation support with armature/bone hierarchy
- Callback system for animation events

### Key Files for Understanding
- `UntoldEngine4D/Director/U4DDirector.h/.mm`: Engine entry point and coordination
- `UntoldEngine4D/Objects/U4DEntity.h/.mm`: Base entity with transformation system
- `UntoldEngine4D/RenderEngine/U4DRenderManager.h/.mm`: Base rendering functionality
- `UntoldEngine4D/PhysicsEngine/U4DPhysicsEngine.h/.mm`: Physics simulation coordinator
- `Game/GameController.h/.mm`: Example game implementation

## Development Guidelines

### Code Style
- C++ with Objective-C++ (.mm files)
- Header files (.h) for declarations, implementation in .mm files
- Consistent U4D prefixing for all engine classes
- RAII principles with proper constructor/destructor patterns
- Manual memory management with careful cleanup methods

### Mathematical Foundation
- Uses dual quaternions for efficient 3D transformations (UntoldEngine4D/MathematicEngine/)
- Vector and matrix classes optimized for graphics operations
- Support for both local and absolute space calculations
- Integration with Metal's SIMD operations

### Asset Pipeline
- **3D Assets**: Supports Blender-exported models with proper coordinate system conversion
- **Textures**: PNG support through lodepng library
- **Fonts**: Bitmap font system with XML descriptors
- **Particles**: Built-in particle system with various emitter shapes
- Custom asset formats (.u4d) for optimized engine data

### Platform Considerations
- Metal API is Apple-specific, so rendering code is platform-locked
- Different entry points for iOS (touch), macOS (mouse/keyboard), tvOS (remote)
- Shared rendering and physics code across all platforms
- Platform-specific optimizations in controller implementations

### Current Limitations
- Pull requests are not currently accepted (per contributing.md)
- Focus is on documentation and stability before accepting contributions
- Beta status means API may change
- Metal dependency limits portability to Apple platforms only

## Testing and Debugging

### Running the Demo
- Default game demo is in Game/ directory
- Shows basic engine functionality: 3D character, particle effects, input handling
- Resources in Resources/ directory include textures, models, and font data

### Common Development Tasks
- Modifying game logic: Edit files in Game/ directory
- Adding new entity types: Inherit from appropriate base class in Objects/
- Custom shaders: Add Metal shaders to MetalShaders/ directory
- New input handling: Extend controllers in Controller/ directory

### Architecture Understanding Tips
- Start with U4DDirector to understand engine flow
- Follow entity hierarchy from U4DEntity upward
- Examine render managers to understand graphics pipeline
- Study collision detection for physics integration patterns
- Look at animation system for component interaction examples

## Task Master AI Instructions
**Import Task Master's development workflow commands and guidelines, treat as if import is in the main CLAUDE.md file.**
@./.taskmaster/CLAUDE.md
