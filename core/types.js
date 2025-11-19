/**
 * CORE TYPES AND CONSTANTS
 *
 * Defines the standard interfaces and enums used throughout the engine.
 * This file has no dependencies and should be loaded first.
 */

// Game States
const GameState = {
    TITLE: 'TITLE',
    TRANSITION: 'TRANSITION',
    PLAYING: 'PLAYING',
    GAME_OVER: 'GAME_OVER'
};

// Microgame Result
const MicrogameResult = {
    ONGOING: 'ongoing',
    WIN: 'win',
    LOSE: 'lose'
};

/**
 * @typedef {Object} DifficultyTier
 * @property {number} tier - Difficulty tier (1-4)
 * @property {number} timeLimitMs - Time limit in milliseconds
 * @property {Object} parameters - Game-specific parameters for this tier
 */

/**
 * @typedef {Object} MicrogameDefinition
 * @property {string} id - Unique identifier
 * @property {string} name - Display name
 * @property {string} instructions - Instruction text shown before game
 * @property {DifficultyTier[]} difficultyTiers - Array of difficulty configurations
 * @property {Function} init - Initialize game (rootElement, parameters)
 * @property {Function} update - Update game state (dt, timeRemainingMs) -> MicrogameResult
 * @property {Function} handleInput - Handle input events (event)
 * @property {Function} cleanup - Clean up resources
 */

// Export to global scope (no modules in this simple setup)
window.GameState = GameState;
window.MicrogameResult = MicrogameResult;
