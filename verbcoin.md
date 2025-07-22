, I'm familiar with Adventure Game Studio (AGS). It's a free, open-source toolset primarily used for creating 2D point-and-click adventure games, inspired by classics from Sierra and LucasArts. It supports scripting in a C-like language, room-based navigation, inventory systems, and various GUI interfaces, including customizable ones like the verb coin style seen in games such as The Curse of Monkey Island.

Below is a comprehensive Product Requirements Document (PRD) for implementing a "Verb Coin Scenario" in a game engine. This assumes we're building or extending a game engine (e.g., something like Unity, Godot, or a custom engine inspired by AGS) to support a verb coin interaction system. The verb coin is a radial or coin-shaped menu that appears on right-click (or equivalent input) near an interactive object or hotspot, presenting icon-based verbs (e.g., eye for "look at," hand for "use/pick up," mouth for "talk to/eat") to streamline player interactions without a persistent verb bar.

I've structured the PRD in a standard format for clarity, focusing on functionality, user experience, technical requirements, and integration. This is designed to be actionable for developers, with assumptions that the engine already handles basic 2D rendering, input, and object management (if not, those would need separate PRDs).

Product Requirements Document (PRD): Verb Coin Interaction System for Adventure Game Engine
1. Document Overview
1.1 Purpose
This PRD outlines the requirements for implementing a verb coin interaction scenario in a game engine, inspired by the interface in The Curse of Monkey Island and adaptable to tools like Adventure Game Studio (AGS). The verb coin replaces traditional verb lists with a contextual, icon-based radial menu that enhances immersion and reduces UI clutter in point-and-click adventure games.

1.2 Scope
In Scope: Core verb coin mechanics, including menu display, verb selection, hotspot interactions, customization options, and integration with inventory and dialogue systems.
Out of Scope: Full game engine development (e.g., rendering pipeline, audio engine); advanced AI for NPCs; multiplayer features; mobile-specific optimizations (though touch input will be considered).
Assumptions: The engine supports 2D sprites, mouse/touch input, event handling, and basic scripting (e.g., via Lua, C#, or AGS-like script). Games using this system will be single-player, narrative-driven adventures.
1.3 Stakeholders
Product Owner: Game designer focused on UX for adventure games.
Development Team: Engine programmers, UI artists, scripters.
End Users: Game developers using the engine; players experiencing the games.
Key Metrics for Success:
Adoption: 80% of sample games use the verb coin without major bugs.
Performance: Menu loads in <50ms; no frame drops during interactions.
Usability: Player feedback scores >4/5 on intuitiveness in playtests.
1.4 Version History
Version 1.0: Initial draft (July 23, 2025).
Future Revisions: Based on feedback or engine updates.
2. Product Objectives
2.1 Business Goals
Enable quick prototyping of adventure games with modern, streamlined interfaces.
Differentiate the engine from competitors (e.g., AGS, Visionaire Studio) by offering customizable, immersive interaction systems.
Reduce development time for UI elements by 30% through reusable components.
2.2 User Goals
Game Developers: Easily script and customize verb coins for hotspots, objects, and NPCs.
Players: Intuitive, context-sensitive interactions that feel natural (e.g., no need to select verbs from a bottom bar; just right-click and choose an icon).
2.3 Key Features
Contextual radial menu triggered by input.
Icon-based verbs with tooltips and animations.
Integration with inventory (e.g., combine items via drag-to-verb).
Scriptable callbacks for custom game logic.
3. Functional Requirements
3.1 Core Mechanics
Triggering the Verb Coin:
On right-click (or long-press on touch devices) over a hotspot/object/NPC, display the verb coin centered at the cursor position.
If no hotspot is under the cursor, perform a default action (e.g., walk to location) or show a minimal coin (e.g., just "look at" for scenery).
Configurable input: Support mouse, keyboard shortcuts (e.g., 'V' for verb menu), gamepad (e.g., right stick), and touch.
Verb Coin Structure:
Radial layout: 3-6 verb icons arranged in a circle or semi-circle (default: 3 for simplicity – Eye, Hand, Mouth).
Icons: Sprite-based, with hover states (e.g., glow on mouse-over).
Tooltips: Display verb text (e.g., "Examine") on hover, with optional voiceover audio cue.
Animation: Fade-in/rotate on appear; subtle spin or pulse for idle state.
Verb Selection and Execution:
Click an icon to select a verb, then apply it to the hotspot (e.g., "Use Hand on Door" triggers open-door script).
If inventory item is selected, modify coin to show item-specific verbs (e.g., "Use Banana on Monkey").
Cancel: Left-click outside the coin or press ESC to dismiss.
Default Verb: Configurable per hotspot (e.g., doors default to "Use").
Contextual Variations:
For NPCs: Prioritize "Talk" verb.
For items: Include "Pick Up" if not in inventory.
For scenery: Limit to "Look At" to prevent invalid actions.
3.2 Integration with Other Systems
Inventory System:
Drag inventory item to hotspot: Auto-show verb coin with relevant verbs (e.g., "Combine").
Verb coin can "hold" an item, allowing verb-item-object syntax (e.g., "Use Key on Lock").
Dialogue System:
"Talk" verb triggers dialogue tree.
Support branching based on prior interactions.
Hotspot Management:
Each hotspot/object has scriptable properties: Available verbs, callbacks for each verb (e.g., OnExamine(), OnUse()).
Hotspots defined via engine editor (e.g., polygon outlines, priority layers for overlapping).
Scripting API:
Expose functions like ShowVerbCoin(x, y, verbs[]) and RegisterVerbCallback(verb, function).
Support custom verbs: Developers can add icons/verbs (e.g., "Parrot" for Monkey Island-style games).
3.3 User Interface Elements
Visual Style: Retro pixel art by default (inspired by AGS), but themeable (e.g., modern vectors).
Accessibility: Color-blind modes for icons; keyboard navigation; screen reader support for tooltips.
Localization: Verbs and tooltips support multiple languages via key-value files.
4. Non-Functional Requirements
4.1 Performance
Load Time: Verb coin renders in <50ms.
Frame Rate: Maintain 60 FPS during menu interactions.
Memory: <5MB additional usage for the system.
4.2 Compatibility
Platforms: Windows, macOS, Linux (desktop); iOS/Android (mobile with touch adaptations); WebGL (browser).
Engine Versions: Compatible with base engine v2.0+ (assuming a hypothetical engine; adapt to Unity/Godot as needed).
Input Devices: Mouse/keyboard, touch, gamepad.
4.3 Security and Reliability
No external dependencies; all assets bundled.
Error Handling: Graceful fallback if verb callback fails (e.g., show "Nothing happens" message).
Testing: Unit tests for verb execution; integration tests with sample scenes.
4.4 Scalability
Support up to 50 hotspots per room without lag.
Customizable verb count (up to 8) without redesign.
5. Technical Specifications
5.1 Architecture
Components:
VerbCoinManager: Singleton handling menu state and input.
VerbIconPrefab: Reusable UI element for each verb.
HotspotComponent: Attached to game objects, stores verbs and callbacks.
Data Structures:
Verb struct: { iconSprite, tooltipText, callbackFunction }.
Hotspot data: Dictionary<VerbType, Action>.
Tech Stack (Assuming a C#-based engine like Unity):
UI Framework: Unity UI or equivalent (e.g., Godot's Control nodes).
Scripting: C# for core; Lua for game-specific logic.
Assets: PNG sprites for icons; Animator for transitions.
5.2 Dependencies
Base engine modules: InputManager, UIManager, ScriptEngine.
No third-party plugins (to match AGS's self-contained nature).
6. User Stories and Acceptance Criteria
6.1 Sample User Stories
As a player, I want to right-click a door to see a verb coin with "Examine," "Open," and "Kick," so I can interact intuitively.
Acceptance: Menu appears at cursor; selecting "Open" triggers animation and room change.
As a developer, I want to add a custom verb "Dance" to an NPC, so I can create unique interactions.
Acceptance: Script adds verb; icon and callback work without errors.
7. Risks and Mitigations
Risk: Input conflicts on touch devices.
Mitigation: Use gesture detection (e.g., tap vs. hold).
Risk: Overly complex customization leads to bugs.
Mitigation: Provide templates and documentation.
Risk: Performance in large rooms.
Mitigation: Optimize hotspot raycasting.
8. Timeline and Milestones
Phase 1 (1-2 weeks): Prototype core menu and triggers.
Phase 2 (2-3 weeks): Integrate with inventory/dialogue; add scripting API.
Phase 3 (1 week): Testing, polish, and documentation.
Total Estimated Time: 4-6 weeks for a small team.
9. Appendices
9.1 References
Inspiration: The Curse of Monkey Island verb coin; AGS documentation on GUI modules.
Wireframes: (Imagine attached sketches – radial menu with 3 icons; hover tooltip.)
Glossary: Hotspot (interactive area); Verb (action like "Use").
This PRD can be iterated based on feedback. If you'd like me to expand on any section, add wireframes (via image generation confirmation), or adapt it for a specific engine like AGS/Unity, let me know!