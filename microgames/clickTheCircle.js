/**
 * MICROGAME: Click the Circle
 *
 * Objective: Click the target circle before time runs out
 * Difficulty scaling:
 * - Tier 1: Large circle, slow shrink
 * - Tier 2: Medium circle, medium shrink
 * - Tier 3: Small circle, fast shrink
 * - Tier 4: Tiny circle, very fast shrink
 */

(function() {
    let container = null;
    let circle = null;
    let hasClicked = false;
    let circleSize = 0;
    let shrinkRate = 0;

    const clickTheCircle = {
        id: 'clickTheCircle',
        name: 'Click the Circle',
        instructions: 'CLICK THE CIRCLE!',

        difficultyTiers: [
            {
                tier: 1,
                timeLimitMs: 4000,
                parameters: {
                    initialSize: 120,
                    shrinkRate: 0.02
                }
            },
            {
                tier: 2,
                timeLimitMs: 3500,
                parameters: {
                    initialSize: 90,
                    shrinkRate: 0.03
                }
            },
            {
                tier: 3,
                timeLimitMs: 3000,
                parameters: {
                    initialSize: 60,
                    shrinkRate: 0.05
                }
            },
            {
                tier: 4,
                timeLimitMs: 2500,
                parameters: {
                    initialSize: 40,
                    shrinkRate: 0.08
                }
            }
        ],

        init(rootElement, params) {
            container = rootElement;
            hasClicked = false;
            circleSize = params.initialSize;
            shrinkRate = params.shrinkRate;

            // Create circle
            circle = document.createElement('div');
            circle.className = 'microgame-element clickable';
            circle.style.width = circleSize + 'px';
            circle.style.height = circleSize + 'px';
            circle.style.background = '#e74c3c';
            circle.style.borderRadius = '50%';
            circle.style.border = '4px solid #fff';
            circle.style.left = '50%';
            circle.style.top = '50%';
            circle.style.transform = 'translate(-50%, -50%)';
            circle.style.cursor = 'pointer';

            circle.addEventListener('click', handleCircleClick);

            container.appendChild(circle);
        },

        update(dt, timeRemaining) {
            if (hasClicked) {
                return MicrogameResult.WIN;
            }

            // Shrink circle over time
            circleSize = Math.max(10, circleSize - (shrinkRate * dt));
            circle.style.width = circleSize + 'px';
            circle.style.height = circleSize + 'px';

            return MicrogameResult.ONGOING;
        },

        handleInput(event) {
            // Input handled via direct click listener
        },

        cleanup() {
            if (circle) {
                circle.removeEventListener('click', handleCircleClick);
                circle.remove();
                circle = null;
            }
            container = null;
        }
    };

    function handleCircleClick(e) {
        e.stopPropagation();
        hasClicked = true;
    }

    // Register the microgame
    MicrogameManager.register(clickTheCircle);
})();
