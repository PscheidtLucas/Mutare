# Mutare 🧬
> Fight to escape extinction through evolution in this short 3D action roguelike.

**[Play Mutare on Itch.io](https://lucas-pscheidt.itch.io/mutare)**

## My Contributions (Lucas Pscheidt)
This project was developed by a team of 4 over 4 months. As a Programmer and Game Designer, my primary focus was architecting scalable, modular systems using **Single Responsibility Principle (SRP)** and creating a polished game feel.

Here are my key technical implementations:

### Systems & Architecture
* **Modular Upgrade Architecture:** Engineered the core system where players attach varying body parts (Heads, Arms, Legs) to a base mesh. This system dynamically alters player behavior, movement, and attacks based on the attached modules. 
* **Scalable Stats System:** Designed and implemented a robust backend to handle 9 interacting player statistics, allowing for complex build variations and easy balancing adjustments.
* **Real-time Equipment Rating System:** Developed an algorithm that evaluates dropped equipment against the player's current build, providing a quick, readable UI rating to help players make fast decisions. 
* **Macro-Loop Evolution Mechanics:** Implemented the core roguelike progression cycle. After surviving 10 waves, the game state resets, absorbing current items into permanent stat bonuses for the next evolutionary cycle.
* **Progressive Difficulty Scaling:** Built a dynamic spawner and enemy scaling system that increases in complexity and stat weight as waves progress.

### Rendering, Polish & Optimization
* **Custom Code-Based Shaders:** Wrote custom GLSL/Godot shaders for 3D environment grass, UI main menu effects, player dash trails, and dynamic upgrade frames to enhance visual juice. 
* **2D/3D Hybrid Rendering:** Successfully integrated 3D models with 2D assets using Godot's SubViewports, creating a unique visual identity and UI integration.
* **VFX, SFX & Game Feel:** Implemented particle systems, audio cues, screen shake, and damage feedback to ensure combat feels impactful.
* **Performance Optimization:** Refactored core loops and managed object pooling to maintain stable framerates despite the high volume of projectiles and enemies in later waves.

---

## 📖 About the Game

**Mutare** is a low-poly 3D action Roguelike where you must evolve your own species to escape extinction. Defeat enemies, collect new body parts, and create unique combinations of arms, legs, and heads that completely change how you move, attack, and survive. 

Between transcendent realms and increasingly intense battles, you shape a bizarre and powerful creature in an endless evolutionary struggle. The further you go, the closer you get to transcending your own limits... or discovering that evolution can also become a dead-end cycle.

## The Team
* **Lucas Pscheidt:** Systems Architecture, Gameplay Programming, UI/UX Implementation, Shaders, Game Design & Balancing.
* **Vitor Cervi:** Game Design, UI/UX Design.
* **Victor Roberto:** 3D Modeler.
* **Dimitri Brandt:** 3d Modeler and Sound Designer.
