/**
 * MICROGAME MANAGER
 *
 * Responsible for:
 * - Registering microgames
 * - Selecting appropriate microgames based on difficulty
 * - Managing difficulty tiers
 */

const MicrogameManager = (function() {
    // Private registry
    const registry = new Map();

    /**
     * Register a new microgame
     * @param {MicrogameDefinition} definition
     */
    function register(definition) {
        // Validate definition
        if (!definition.id || !definition.name || !definition.instructions) {
            console.warn('Skipping invalid microgame: missing required fields', definition);
            return;
        }

        if (!definition.difficultyTiers || definition.difficultyTiers.length === 0) {
            console.warn('Skipping microgame: no difficulty tiers', definition.id);
            return;
        }

        if (typeof definition.init !== 'function' ||
            typeof definition.update !== 'function' ||
            typeof definition.handleInput !== 'function' ||
            typeof definition.cleanup !== 'function') {
            console.warn('Skipping microgame: missing required methods', definition.id);
            return;
        }

        registry.set(definition.id, definition);
        console.log(`Registered microgame: ${definition.id}`);
    }

    /**
     * Get all registered microgames
     * @returns {MicrogameDefinition[]}
     */
    function getAll() {
        return Array.from(registry.values());
    }

    /**
     * Select a random microgame that supports the given difficulty tier
     * @param {number} currentTier - Current difficulty tier (1-4)
     * @returns {Object} { definition, tierConfig } or null
     */
    function selectMicrogame(currentTier) {
        const allGames = getAll();

        // Filter games that support the current tier
        const eligibleGames = allGames.filter(game => {
            const maxTier = Math.max(...game.difficultyTiers.map(t => t.tier));
            return maxTier >= currentTier;
        });

        if (eligibleGames.length === 0) {
            console.error('No microgames support tier', currentTier);
            return null;
        }

        // Pick a random eligible game
        const selectedGame = eligibleGames[Math.floor(Math.random() * eligibleGames.length)];

        // Find the highest tier config that doesn't exceed currentTier
        const tierConfig = selectedGame.difficultyTiers
            .filter(t => t.tier <= currentTier)
            .sort((a, b) => b.tier - a.tier)[0];

        return {
            definition: selectedGame,
            tierConfig: tierConfig
        };
    }

    /**
     * Get count of registered microgames
     */
    function getCount() {
        return registry.size;
    }

    // Public API
    return {
        register,
        getAll,
        selectMicrogame,
        getCount
    };
})();

// Export to global
window.MicrogameManager = MicrogameManager;
