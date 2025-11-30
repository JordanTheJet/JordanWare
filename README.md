# WarioWare Microgame Platform

A fully extensible WarioWare-style microgame engine built with **Godot 4**.

## 🎮 Two Implementations Available

### 1. Web Version (HTML/CSS/JavaScript)
- Located in root directory (when on `claude/warioware-microgame-platform-*` branch)
- Runs directly in browser, no build step
- Perfect for quick prototyping and web deployment

### 2. Godot Version (This Branch)
- Located in `godot-project/` directory
- Cross-platform export capabilities
- Professional game engine features
- **Recommended for production**

---

## 🚀 Godot Version - Quick Start

### Prerequisites
- **Godot 4.3+** ([Download here](https://godotengine.org/download))

### How to Run
1. Download/clone this repository
2. Open Godot Engine
3. Click "Import"
4. Navigate to `godot-project/project.godot`
5. Click "Import & Edit"
6. Press **F5** to run the game!

---

## 📦 Project Structure

```
godot-project/
├── project.godot              # Godot project configuration
├── icon.svg                   # Project icon
├── scenes/
│   ├── main.tscn             # Main game scene
│   └── microgames/           # Individual microgame scenes
│       ├── click_circle.tscn
│       ├── dodge_block.tscn
│       ├── mash_key.tscn
│       ├── dont_click.tscn
│       ├── drag_target.tscn
│       └── catch_falling.tscn
├── scripts/
│   ├── game_engine.gd        # Main game controller
│   ├── microgame_manager.gd  # Microgame registry & selection
│   ├── microgame_base.gd     # Base class for all microgames
│   ├── ui_controller.gd      # UI management
│   └── microgames/           # Individual microgame scripts
│       ├── click_circle.gd
│       ├── dodge_block.gd
│       ├── mash_key.gd
│       ├── dont_click.gd
│       ├── drag_target.gd
│       └── catch_falling.gd
└── assets/
    └── fonts/                # Custom fonts (optional)
```

---

## 🎯 Features

### ✨ Core Features
- **Plugin Architecture** - Add new microgames without modifying engine code
- **4-Tier Difficulty System** - Each microgame scales across 4 difficulty levels
- **Multi-Dimensional Scaling** - Time limits, speeds, sizes, counts, cognitive load
- **Clean Lifecycle** - Proper init/cleanup prevents memory leaks
- **Cross-Platform Export** - Windows, Mac, Linux, Web, Mobile, Consoles

### 🎲 Included Microgames (6 Total)
1. **Click the Circle** - Shrinking target clicking challenge
2. **Dodge the Block** - Avoid falling obstacles
3. **Mash the Key** - Rapid key pressing with decay
4. **Don't Click** - Negation challenge with moving distractors
5. **Drag to Target** - Mouse precision and dragging
6. **Catch the Falling** - Timing-based catching game

### 🎚️ Difficulty Progression
- Starts at Tier 1
- Increases every 5 consecutive wins OR every 10 score points
- Maximum Tier 4
- Each microgame defines custom parameters per tier

---

## 🛠️ How to Add a New Microgame

### 1. Create the Script

Create `scripts/microgames/your_game.gd`:

```gdscript
extends MicrogameBase

func _define_difficulty_tiers() -> void:
    microgame_id = "your_game"
    microgame_name = "Your Game Name"
    instructions = "DO SOMETHING!"

    difficulty_tiers = [
        {
            "tier": 1,
            "time_limit": 5.0,
            "parameters": { "speed": 100.0 }
        },
        {
            "tier": 2,
            "time_limit": 4.0,
            "parameters": { "speed": 200.0 }
        },
        # Add tiers 3 and 4...
    ]

func _setup_game() -> void:
    # Create your game elements here
    pass

func _on_game_start() -> void:
    # Initialize game state with current_parameters
    pass

func _update_game(delta: float) -> void:
    # Update game logic
    # Call _win_game() or _lose_game() when appropriate
    pass
```

### 2. Create the Scene

1. In Godot, create a new scene: `Scene` → `New Scene`
2. Add a `Node2D` as root
3. Attach your script to it
4. Save as `scenes/microgames/your_game.tscn`

### 3. Register in Manager

Open `scripts/microgame_manager.gd` and add to the `microgame_scenes` array:

```gdscript
@export var microgame_scenes: Array[String] = [
    # ... existing games ...
    "res://scenes/microgames/your_game.tscn",
]
```

**That's it!** The engine will automatically discover and use your microgame.

---

## 📤 Exporting Your Game

### Export to Multiple Platforms

1. Go to `Project` → `Export`
2. Click `Add...` and select your target platform(s):
   - **Windows Desktop**
   - **macOS**
   - **Linux/X11**
   - **Web (HTML5)**
   - **Android** (requires Android SDK)
   - **iOS** (requires macOS and Xcode)
3. Configure export settings
4. Click `Export Project`

### Export Templates
First time exporting? Godot will prompt you to download export templates. Click "Manage Export Templates" and download for your Godot version.

### Web Export Tips
- Enable `Thread Support` for better performance
- Use `SharedArrayBuffer` for threading (requires HTTPS or localhost)
- Test in multiple browsers

---

## 🎨 Customization

### Changing Game Settings

Edit `scripts/game_engine.gd`:

```gdscript
const STARTING_LIVES = 3                # Starting lives
const TRANSITION_DURATION = 2.0         # Instruction display time
const WINS_PER_TIER_INCREASE = 5        # Wins needed for difficulty increase
const SCORE_MILESTONE_INTERVAL = 10     # Score milestone for difficulty increase
```

### Styling the UI

- Edit `scenes/main.tscn` in Godot's editor
- Modify colors, fonts, sizes in the Inspector
- Add custom themes via `Project Settings` → `GUI`

### Adding Sound Effects

1. Import audio files to `assets/sounds/`
2. Add `AudioStreamPlayer` nodes to scenes
3. Play sounds in microgame scripts:
   ```gdscript
   $SoundEffect.play()
   ```

---

## 🏗️ Architecture Overview

### Game States
- **TITLE** - Main menu
- **TRANSITION** - Shows instruction for 2 seconds
- **PLAYING** - Active microgame
- **GAME_OVER** - Final score screen

### Microgame Lifecycle
1. `_define_difficulty_tiers()` - Define tier configurations
2. `_setup_game()` - Create game elements
3. `start_game(tier)` - Engine calls this with current tier
4. `_on_game_start()` - Initialize with tier parameters
5. `_update_game(delta)` - Update every frame
6. `_win_game()` / `_lose_game()` - Signal completion
7. `cleanup()` - Remove all elements

### Signals
- `game_won` - Emitted when player wins
- `game_lost` - Emitted when player loses or time expires

---

## 🐛 Troubleshooting

### Game won't start
- Check console for errors (Output panel in Godot)
- Verify all microgame scenes are in `scripts/microgame_manager.gd`
- Ensure `main.tscn` is set as main scene in `project.godot`

### Microgame not loading
- Check that script extends `MicrogameBase`
- Verify `microgame_id` and `microgame_name` are set
- Ensure `difficulty_tiers` array is not empty
- Check scene path in MicrogameManager

### Export fails
- Download export templates for your Godot version
- Check export preset configuration
- Enable required permissions (especially for mobile)

---

## 📚 Learn More

- [Godot Documentation](https://docs.godotengine.org/)
- [GDScript Reference](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html)
- [Godot Export Documentation](https://docs.godotengine.org/en/stable/tutorials/export/index.html)

---

## 🤝 Contributing

Feel free to:
- Add new microgames
- Improve existing ones
- Add visual/audio polish
- Optimize performance
- Report bugs

---

## 📝 License

This project is open source and available for educational and commercial use.

---

## 🎮 Enjoy Creating Microgames!

Built with ❤️ using Godot Engine
