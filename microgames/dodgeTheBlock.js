/**
 * MICROGAME: Dodge the Block
 *
 * Objective: Dodge falling blocks by moving the mouse
 * Difficulty scaling:
 * - Tier 1: Few blocks, slow speed
 * - Tier 2: More blocks, medium speed
 * - Tier 3: Many blocks, fast speed
 * - Tier 4: Many blocks, very fast, smaller player
 */

(function() {
    let container = null;
    let player = null;
    let blocks = [];
    let playerX = 400;
    let hasLost = false;
    let blockSpeed = 0;
    let blockCount = 0;
    let playerSize = 0;

    const dodgeTheBlock = {
        id: 'dodgeTheBlock',
        name: 'Dodge the Block',
        instructions: 'DODGE THE BLOCKS!',

        difficultyTiers: [
            {
                tier: 1,
                timeLimitMs: 4000,
                parameters: {
                    blockSpeed: 0.15,
                    blockCount: 3,
                    playerSize: 40
                }
            },
            {
                tier: 2,
                timeLimitMs: 3500,
                parameters: {
                    blockSpeed: 0.25,
                    blockCount: 5,
                    playerSize: 35
                }
            },
            {
                tier: 3,
                timeLimitMs: 3000,
                parameters: {
                    blockSpeed: 0.35,
                    blockCount: 7,
                    playerSize: 30
                }
            },
            {
                tier: 4,
                timeLimitMs: 2500,
                parameters: {
                    blockSpeed: 0.5,
                    blockCount: 9,
                    playerSize: 25
                }
            }
        ],

        init(rootElement, params) {
            container = rootElement;
            hasLost = false;
            blocks = [];
            blockSpeed = params.blockSpeed;
            blockCount = params.blockCount;
            playerSize = params.playerSize;
            playerX = 400;

            // Create player
            player = document.createElement('div');
            player.className = 'microgame-element';
            player.style.width = playerSize + 'px';
            player.style.height = playerSize + 'px';
            player.style.background = '#3498db';
            player.style.border = '3px solid #fff';
            player.style.bottom = '20px';
            player.style.left = (playerX - playerSize / 2) + 'px';
            container.appendChild(player);

            // Create blocks
            for (let i = 0; i < blockCount; i++) {
                createBlock(i * (500 / blockCount));
            }
        },

        update(dt, timeRemaining) {
            if (hasLost) {
                return MicrogameResult.LOSE;
            }

            // Update player position
            player.style.left = (playerX - playerSize / 2) + 'px';

            // Move blocks down
            blocks.forEach(block => {
                block.y += blockSpeed * dt;
                block.element.style.top = block.y + 'px';

                // Check collision
                if (checkCollision(block)) {
                    hasLost = true;
                }

                // Reset if off screen
                if (block.y > 550) {
                    block.y = -50;
                    block.x = Math.random() * 740 + 30;
                    block.element.style.left = block.x + 'px';
                }
            });

            return MicrogameResult.ONGOING;
        },

        handleInput(event) {
            if (event.type === 'mousemove') {
                const rect = container.getBoundingClientRect();
                playerX = Math.max(playerSize / 2, Math.min(800 - playerSize / 2, event.clientX - rect.left));
            }
        },

        cleanup() {
            if (player) {
                player.remove();
                player = null;
            }
            blocks.forEach(block => block.element.remove());
            blocks = [];
            container = null;
        }
    };

    function createBlock(yOffset) {
        const blockElement = document.createElement('div');
        blockElement.className = 'microgame-element';
        blockElement.style.width = '40px';
        blockElement.style.height = '40px';
        blockElement.style.background = '#e74c3c';
        blockElement.style.border = '3px solid #fff';

        const x = Math.random() * 740 + 30;
        const y = -50 - yOffset;

        blockElement.style.left = x + 'px';
        blockElement.style.top = y + 'px';

        container.appendChild(blockElement);

        blocks.push({
            element: blockElement,
            x: x,
            y: y,
            size: 40
        });
    }

    function checkCollision(block) {
        const playerLeft = playerX - playerSize / 2;
        const playerRight = playerX + playerSize / 2;
        const playerTop = 550 - 20 - playerSize;
        const playerBottom = 550 - 20;

        const blockLeft = block.x;
        const blockRight = block.x + block.size;
        const blockTop = block.y;
        const blockBottom = block.y + block.size;

        return !(playerRight < blockLeft ||
                 playerLeft > blockRight ||
                 playerBottom < blockTop ||
                 playerTop > blockBottom);
    }

    MicrogameManager.register(dodgeTheBlock);
})();
