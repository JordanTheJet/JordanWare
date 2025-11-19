/**
 * ═══════════════════════════════════════════════════════════════════════════
 * WARIOWARE MICROGAME ENGINE - README
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ARCHITECTURE OVERVIEW
 * ---------------------
 * This engine uses a modular, plugin-based architecture that allows unlimited
 * expansion without modifying core engine code.
 *
 *
 * FOLDER STRUCTURE
 * ----------------
 * /
 * ├── index.html                 - Main HTML file
 * ├── style.css                  - Global styles
 * ├── /core/
 * │   └── types.js               - Shared type definitions and constants
 * ├── /engine/
 * │   ├── microgameManager.js    - Microgame registry and selection
 * │   └── gameEngine.js          - Main game loop and state management (THIS FILE)
 * └── /microgames/
 *     ├── clickTheCircle.js      - Example microgame
 *     ├── dodgeTheBlock.js       - Example microgame
 *     └── ...                    - Add more here!
 *
 *
 * HOW MICROGAME LOADING WORKS
 * ---------------------------
 * 1. Each microgame is a separate .js file in /microgames/
 * 2. Microgame files are loaded via <script> tags in index.html
 * 3. Each microgame calls MicrogameManager.register() with its definition
 * 4. The engine automatically discovers all registered microgames at runtime
 * 5. No engine modifications needed - just add the <script> tag!
 *
 *
 * HOW DIFFICULTY SCALING WORKS
 * ----------------------------
 * Difficulty is multi-dimensional:
 *
 * 1. GLOBAL TIER (1-4): Increases based on player performance
 *    - Every 5 consecutive wins: tier++
 *    - Score milestones (10, 20, 30, etc.): tier++
 *    - Capped at tier 4
 *
 * 2. TIER PARAMETERS: Each microgame defines different parameters per tier
 *    - Tier 1: Longest time, easiest parameters
 *    - Tier 4: Shortest time, hardest parameters
 *    - Parameters can include: speed, count, size, precision, etc.
 *
 * 3. SELECTION LOGIC:
 *    - Engine selects microgames that support current tier
 *    - Uses the highest tier config ≤ current difficulty
 *    - Random selection from eligible pool
 *
 *
 * HOW TO ADD A NEW MICROGAME
 * --------------------------
 * 1. Create a new file: /microgames/yourGame.js
 *
 * 2. Define your microgame following this template:
 *
 *    (function() {
 *        // Your game state
 *        let gameState = {};
 *
 *        const yourGameDefinition = {
 *            id: 'yourGameId',
 *            name: 'Your Game Name',
 *            instructions: 'DO SOMETHING!',
 *
 *            difficultyTiers: [
 *                { tier: 1, timeLimitMs: 5000, parameters: { speed: 1 } },
 *                { tier: 2, timeLimitMs: 4000, parameters: { speed: 2 } },
 *                { tier: 3, timeLimitMs: 3000, parameters: { speed: 3 } },
 *                { tier: 4, timeLimitMs: 2500, parameters: { speed: 4 } }
 *            ],
 *
 *            init(container, params) {
 *                // Set up your game DOM, state, etc.
 *                // Use params for difficulty-specific values
 *            },
 *
 *            update(dt, timeRemaining) {
 *                // Update game logic
 *                // Return 'win', 'lose', or 'ongoing'
 *                return 'ongoing';
 *            },
 *
 *            handleInput(event) {
 *                // Handle clicks, keypresses, etc.
 *            },
 *
 *            cleanup() {
 *                // Remove all DOM elements and event listeners
 *                // CRITICAL: Clean up everything to prevent conflicts!
 *            }
 *        };
 *
 *        MicrogameManager.register(yourGameDefinition);
 *    })();
 *
 * 3. Add a <script> tag in index.html:
 *    <script src="microgames/yourGame.js"></script>
 *
 * 4. That's it! The engine will automatically discover and use your game.
 *
 *
 * CONFIGURATION
 * -------------
 * Modify these constants in GameEngine to tune the overall experience:
 * - STARTING_LIVES
 * - TRANSITION_DURATION_MS
 * - WINS_PER_TIER_INCREASE
 * - SCORE_MILESTONE_INTERVAL
 *
 * ═══════════════════════════════════════════════════════════════════════════
 */

const GameEngine = (function() {
    // ========================================================================
    // CONFIGURATION
    // ========================================================================
    const STARTING_LIVES = 3;
    const TRANSITION_DURATION_MS = 2000;
    const WINS_PER_TIER_INCREASE = 5;
    const SCORE_MILESTONE_INTERVAL = 10;

    // ========================================================================
    // STATE
    // ========================================================================
    let currentState = GameState.TITLE;
    let score = 0;
    let lives = STARTING_LIVES;
    let difficultyTier = 1;
    let consecutiveWins = 0;

    let currentMicrogame = null;
    let currentTierConfig = null;
    let microgameStartTime = 0;
    let transitionStartTime = 0;

    let lastFrameTime = 0;
    let animationFrameId = null;

    // ========================================================================
    // DOM ELEMENTS
    // ========================================================================
    const elements = {};

    function cacheDOMElements() {
        elements.hud = document.getElementById('hud');
        elements.scoreDisplay = document.getElementById('score');
        elements.livesDisplay = document.getElementById('lives');
        elements.difficultyDisplay = document.getElementById('difficulty');

        elements.titleScreen = document.getElementById('title-screen');
        elements.transitionScreen = document.getElementById('transition-screen');
        elements.playingScreen = document.getElementById('playing-screen');
        elements.gameoverScreen = document.getElementById('gameover-screen');
        elements.gameScreen = document.getElementById('game-screen');

        elements.instructionText = document.getElementById('instruction-text');
        elements.finalScore = document.getElementById('final-score');

        elements.startButton = document.getElementById('start-button');
        elements.restartButton = document.getElementById('restart-button');

        elements.timerBar = document.getElementById('timer-bar');
    }

    // ========================================================================
    // INITIALIZATION
    // ========================================================================
    function init() {
        cacheDOMElements();

        // Event listeners
        elements.startButton.addEventListener('click', startGame);
        elements.restartButton.addEventListener('click', restartGame);

        // Check that microgames are loaded
        console.log(`Loaded ${MicrogameManager.getCount()} microgames`);

        if (MicrogameManager.getCount() === 0) {
            console.error('No microgames loaded! Check your script tags in index.html');
        }

        showScreen(GameState.TITLE);
    }

    // ========================================================================
    // GAME FLOW
    // ========================================================================
    function startGame() {
        score = 0;
        lives = STARTING_LIVES;
        difficultyTier = 1;
        consecutiveWins = 0;

        updateHUD();
        startNextMicrogame();
    }

    function restartGame() {
        startGame();
    }

    function startNextMicrogame() {
        // Select a microgame
        const selection = MicrogameManager.selectMicrogame(difficultyTier);

        if (!selection) {
            console.error('Failed to select microgame');
            gameOver();
            return;
        }

        currentMicrogame = selection.definition;
        currentTierConfig = selection.tierConfig;

        // Show transition screen
        currentState = GameState.TRANSITION;
        showScreen(GameState.TRANSITION);
        elements.instructionText.textContent = currentMicrogame.instructions;
        transitionStartTime = performance.now();

        if (!animationFrameId) {
            gameLoop(performance.now());
        }
    }

    function startMicrogamePlay() {
        currentState = GameState.PLAYING;
        showScreen(GameState.PLAYING);

        // Clear playing screen
        elements.playingScreen.innerHTML = '';

        // Initialize the microgame
        try {
            currentMicrogame.init(
                elements.playingScreen,
                currentTierConfig.parameters
            );
            microgameStartTime = performance.now();
        } catch (error) {
            console.error('Error initializing microgame:', error);
            handleMicrogameLose();
        }
    }

    function handleMicrogameWin() {
        score++;
        consecutiveWins++;

        // Flash green
        elements.gameScreen.classList.add('flash-win');
        setTimeout(() => elements.gameScreen.classList.remove('flash-win'), 500);

        cleanupCurrentMicrogame();
        checkDifficultyIncrease();
        updateHUD();

        setTimeout(() => startNextMicrogame(), 600);
    }

    function handleMicrogameLose() {
        lives--;
        consecutiveWins = 0;

        // Flash red
        elements.gameScreen.classList.add('flash-lose');
        setTimeout(() => elements.gameScreen.classList.remove('flash-lose'), 500);

        cleanupCurrentMicrogame();
        updateHUD();

        if (lives <= 0) {
            setTimeout(() => gameOver(), 600);
        } else {
            setTimeout(() => startNextMicrogame(), 600);
        }
    }

    function cleanupCurrentMicrogame() {
        if (currentMicrogame && currentMicrogame.cleanup) {
            try {
                currentMicrogame.cleanup();
            } catch (error) {
                console.error('Error cleaning up microgame:', error);
            }
        }
        currentMicrogame = null;
        currentTierConfig = null;
    }

    function gameOver() {
        currentState = GameState.GAME_OVER;
        showScreen(GameState.GAME_OVER);
        elements.finalScore.textContent = `Final Score: ${score}`;

        if (animationFrameId) {
            cancelAnimationFrame(animationFrameId);
            animationFrameId = null;
        }
    }

    // ========================================================================
    // DIFFICULTY SCALING
    // ========================================================================
    function checkDifficultyIncrease() {
        let shouldIncrease = false;

        // Check consecutive wins
        if (consecutiveWins >= WINS_PER_TIER_INCREASE) {
            shouldIncrease = true;
            consecutiveWins = 0;
        }

        // Check score milestones
        if (score > 0 && score % SCORE_MILESTONE_INTERVAL === 0) {
            shouldIncrease = true;
        }

        if (shouldIncrease && difficultyTier < 4) {
            difficultyTier++;
            console.log(`Difficulty increased to tier ${difficultyTier}`);
        }
    }

    // ========================================================================
    // GAME LOOP
    // ========================================================================
    function gameLoop(timestamp) {
        const dt = timestamp - lastFrameTime;
        lastFrameTime = timestamp;

        if (currentState === GameState.TRANSITION) {
            const elapsed = timestamp - transitionStartTime;
            if (elapsed >= TRANSITION_DURATION_MS) {
                startMicrogamePlay();
            }
        }

        if (currentState === GameState.PLAYING && currentMicrogame) {
            const elapsed = timestamp - microgameStartTime;
            const timeRemaining = currentTierConfig.timeLimitMs - elapsed;

            // Update timer bar
            const progress = Math.max(0, timeRemaining / currentTierConfig.timeLimitMs);
            elements.timerBar.style.width = (progress * 100) + '%';

            // Check timeout
            if (timeRemaining <= 0) {
                handleMicrogameLose();
                return;
            }

            // Update microgame
            try {
                const result = currentMicrogame.update(dt, timeRemaining);

                if (result === MicrogameResult.WIN) {
                    handleMicrogameWin();
                    return;
                } else if (result === MicrogameResult.LOSE) {
                    handleMicrogameLose();
                    return;
                }
            } catch (error) {
                console.error('Error updating microgame:', error);
                handleMicrogameLose();
                return;
            }
        }

        animationFrameId = requestAnimationFrame(gameLoop);
    }

    // ========================================================================
    // INPUT HANDLING
    // ========================================================================
    function handleGlobalInput(event) {
        if (currentState === GameState.PLAYING && currentMicrogame) {
            try {
                currentMicrogame.handleInput(event);
            } catch (error) {
                console.error('Error handling input in microgame:', error);
            }
        }
    }

    // Global input listeners
    document.addEventListener('keydown', handleGlobalInput);
    document.addEventListener('keyup', handleGlobalInput);
    document.addEventListener('click', handleGlobalInput);
    document.addEventListener('mousedown', handleGlobalInput);
    document.addEventListener('mouseup', handleGlobalInput);
    document.addEventListener('mousemove', handleGlobalInput);

    // ========================================================================
    // UI UPDATES
    // ========================================================================
    function updateHUD() {
        elements.scoreDisplay.textContent = `Score: ${score}`;
        elements.livesDisplay.textContent = `Lives: ${'❤️'.repeat(lives)}`;
        elements.difficultyDisplay.textContent = `Tier: ${difficultyTier}`;
    }

    function showScreen(state) {
        elements.titleScreen.classList.add('hidden');
        elements.transitionScreen.classList.add('hidden');
        elements.playingScreen.classList.add('hidden');
        elements.gameoverScreen.classList.add('hidden');

        switch (state) {
            case GameState.TITLE:
                elements.titleScreen.classList.remove('hidden');
                elements.hud.style.display = 'none';
                elements.timerBar.style.width = '100%';
                break;
            case GameState.TRANSITION:
                elements.transitionScreen.classList.remove('hidden');
                elements.hud.style.display = 'flex';
                elements.timerBar.style.width = '100%';
                break;
            case GameState.PLAYING:
                elements.playingScreen.classList.remove('hidden');
                elements.hud.style.display = 'flex';
                break;
            case GameState.GAME_OVER:
                elements.gameoverScreen.classList.remove('hidden');
                elements.hud.style.display = 'flex';
                elements.timerBar.style.width = '0%';
                break;
        }
    }

    // ========================================================================
    // PUBLIC API
    // ========================================================================
    return {
        init
    };
})();

// Start the engine when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => GameEngine.init());
} else {
    GameEngine.init();
}
