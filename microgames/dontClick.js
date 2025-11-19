/**
 * MICROGAME: Don't Click
 *
 * Objective: DON'T click anywhere! (negation challenge)
 * Difficulty scaling:
 * - Tier 1: Longer time, no distractors
 * - Tier 2: Shorter time, fake buttons
 * - Tier 3: Even shorter, moving distractors
 * - Tier 4: Very short, many moving distractors
 */

(function() {
    let container = null;
    let hasClicked = false;
    let distractors = [];
    let distractorCount = 0;

    const dontClick = {
        id: 'dontClick',
        name: "Don't Click",
        instructions: "DON'T CLICK!",

        difficultyTiers: [
            {
                tier: 1,
                timeLimitMs: 3000,
                parameters: {
                    distractorCount: 0,
                    moving: false
                }
            },
            {
                tier: 2,
                timeLimitMs: 3000,
                parameters: {
                    distractorCount: 3,
                    moving: false
                }
            },
            {
                tier: 3,
                timeLimitMs: 2500,
                parameters: {
                    distractorCount: 5,
                    moving: true
                }
            },
            {
                tier: 4,
                timeLimitMs: 2500,
                parameters: {
                    distractorCount: 8,
                    moving: true
                }
            }
        ],

        init(rootElement, params) {
            container = rootElement;
            hasClicked = false;
            distractors = [];
            distractorCount = params.distractorCount;

            // Create warning text
            const warning = document.createElement('div');
            warning.style.position = 'absolute';
            warning.style.top = '50%';
            warning.style.left = '50%';
            warning.style.transform = 'translate(-50%, -50%)';
            warning.style.fontSize = '48px';
            warning.style.color = '#e74c3c';
            warning.style.textAlign = 'center';
            warning.style.fontWeight = 'bold';
            warning.style.textShadow = '3px 3px 0 #000';
            warning.textContent = 'RESIST!';
            container.appendChild(warning);

            // Create distractors
            for (let i = 0; i < distractorCount; i++) {
                createDistractor(params.moving);
            }
        },

        update(dt, timeRemaining) {
            if (hasClicked) {
                return MicrogameResult.LOSE;
            }

            // Move distractors if applicable
            distractors.forEach(distractor => {
                if (distractor.moving) {
                    distractor.x += distractor.vx * dt * 0.1;
                    distractor.y += distractor.vy * dt * 0.1;

                    // Bounce off edges
                    if (distractor.x < 0 || distractor.x > 750) distractor.vx *= -1;
                    if (distractor.y < 0 || distractor.y > 500) distractor.vy *= -1;

                    distractor.element.style.left = distractor.x + 'px';
                    distractor.element.style.top = distractor.y + 'px';
                }
            });

            return MicrogameResult.ONGOING;
        },

        handleInput(event) {
            if (event.type === 'click' || event.type === 'mousedown') {
                hasClicked = true;
            }
        },

        cleanup() {
            distractors.forEach(d => d.element.remove());
            distractors = [];
            if (container) {
                container.innerHTML = '';
            }
            container = null;
        }
    };

    function createDistractor(moving) {
        const button = document.createElement('button');
        button.textContent = ['CLICK ME!', 'PRESS!', 'TAP HERE!', 'DO IT!'][Math.floor(Math.random() * 4)];
        button.style.position = 'absolute';
        button.style.padding = '15px 30px';
        button.style.fontSize = '20px';
        button.style.cursor = 'pointer';

        const x = Math.random() * 600 + 100;
        const y = Math.random() * 400 + 50;

        button.style.left = x + 'px';
        button.style.top = y + 'px';

        container.appendChild(button);

        distractors.push({
            element: button,
            x: x,
            y: y,
            vx: moving ? (Math.random() - 0.5) * 2 : 0,
            vy: moving ? (Math.random() - 0.5) * 2 : 0,
            moving: moving
        });
    }

    MicrogameManager.register(dontClick);
})();
