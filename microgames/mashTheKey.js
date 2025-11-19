/**
 * MICROGAME: Mash the Key
 *
 * Objective: Press the specified key rapidly to fill the bar
 * Difficulty scaling:
 * - Tier 1: Low target, any key
 * - Tier 2: Medium target, specific key
 * - Tier 3: High target, specific key
 * - Tier 4: Very high target, specific key, faster decay
 */

(function() {
    let container = null;
    let progressBar = null;
    let keyDisplay = null;
    let progress = 0;
    let targetKey = null;
    let requiredPresses = 0;
    let decayRate = 0;
    let currentPresses = 0;

    const mashTheKey = {
        id: 'mashTheKey',
        name: 'Mash the Key',
        instructions: 'MASH THE KEY!',

        difficultyTiers: [
            {
                tier: 1,
                timeLimitMs: 4000,
                parameters: {
                    requiredPresses: 15,
                    specificKey: null, // any key
                    decayRate: 0.005
                }
            },
            {
                tier: 2,
                timeLimitMs: 3500,
                parameters: {
                    requiredPresses: 20,
                    specificKey: 'SPACE',
                    decayRate: 0.008
                }
            },
            {
                tier: 3,
                timeLimitMs: 3000,
                parameters: {
                    requiredPresses: 25,
                    specificKey: 'A',
                    decayRate: 0.01
                }
            },
            {
                tier: 4,
                timeLimitMs: 2500,
                parameters: {
                    requiredPresses: 30,
                    specificKey: 'X',
                    decayRate: 0.015
                }
            }
        ],

        init(rootElement, params) {
            container = rootElement;
            progress = 0;
            currentPresses = 0;
            requiredPresses = params.requiredPresses;
            targetKey = params.specificKey;
            decayRate = params.decayRate;

            // Create instruction
            const instruction = document.createElement('div');
            instruction.style.position = 'absolute';
            instruction.style.top = '100px';
            instruction.style.left = '50%';
            instruction.style.transform = 'translateX(-50%)';
            instruction.style.fontSize = '32px';
            instruction.style.color = '#fff';
            instruction.style.textAlign = 'center';
            instruction.textContent = targetKey ? `Press ${targetKey}!` : 'Press ANY key!';
            container.appendChild(instruction);

            // Create key display
            keyDisplay = document.createElement('div');
            keyDisplay.style.position = 'absolute';
            keyDisplay.style.top = '200px';
            keyDisplay.style.left = '50%';
            keyDisplay.style.transform = 'translateX(-50%)';
            keyDisplay.style.width = '120px';
            keyDisplay.style.height = '120px';
            keyDisplay.style.background = '#34495e';
            keyDisplay.style.border = '5px solid #fff';
            keyDisplay.style.borderRadius = '15px';
            keyDisplay.style.display = 'flex';
            keyDisplay.style.alignItems = 'center';
            keyDisplay.style.justifyContent = 'center';
            keyDisplay.style.fontSize = '48px';
            keyDisplay.style.fontWeight = 'bold';
            keyDisplay.style.color = '#fff';
            keyDisplay.textContent = targetKey || '?';
            container.appendChild(keyDisplay);

            // Create progress bar container
            const barContainer = document.createElement('div');
            barContainer.style.position = 'absolute';
            barContainer.style.bottom = '100px';
            barContainer.style.left = '50%';
            barContainer.style.transform = 'translateX(-50%)';
            barContainer.style.width = '600px';
            barContainer.style.height = '50px';
            barContainer.style.background = '#34495e';
            barContainer.style.border = '4px solid #fff';
            barContainer.style.borderRadius = '10px';
            barContainer.style.overflow = 'hidden';
            container.appendChild(barContainer);

            // Create progress bar
            progressBar = document.createElement('div');
            progressBar.style.width = '0%';
            progressBar.style.height = '100%';
            progressBar.style.background = 'linear-gradient(90deg, #2ecc71, #f39c12)';
            progressBar.style.transition = 'width 0.1s';
            barContainer.appendChild(progressBar);

            // Create counter
            const counter = document.createElement('div');
            counter.id = 'press-counter';
            counter.style.position = 'absolute';
            counter.style.bottom = '160px';
            counter.style.left = '50%';
            counter.style.transform = 'translateX(-50%)';
            counter.style.fontSize = '28px';
            counter.style.color = '#fff';
            counter.textContent = `0 / ${requiredPresses}`;
            container.appendChild(counter);
        },

        update(dt, timeRemaining) {
            // Decay progress
            progress = Math.max(0, progress - decayRate * dt);
            currentPresses = Math.floor(progress);

            // Update progress bar
            const percentage = (currentPresses / requiredPresses) * 100;
            progressBar.style.width = Math.min(100, percentage) + '%';

            // Update counter
            const counter = container.querySelector('#press-counter');
            if (counter) {
                counter.textContent = `${currentPresses} / ${requiredPresses}`;
            }

            // Check win
            if (currentPresses >= requiredPresses) {
                return MicrogameResult.WIN;
            }

            return MicrogameResult.ONGOING;
        },

        handleInput(event) {
            if (event.type === 'keydown') {
                let validPress = false;

                if (!targetKey) {
                    validPress = true;
                } else if (targetKey === 'SPACE' && event.code === 'Space') {
                    validPress = true;
                } else if (event.key.toUpperCase() === targetKey) {
                    validPress = true;
                }

                if (validPress) {
                    progress += 1;
                    // Flash effect
                    keyDisplay.style.background = '#2ecc71';
                    setTimeout(() => {
                        if (keyDisplay) keyDisplay.style.background = '#34495e';
                    }, 100);
                }
            }
        },

        cleanup() {
            if (container) {
                container.innerHTML = '';
            }
            container = null;
            progressBar = null;
            keyDisplay = null;
        }
    };

    MicrogameManager.register(mashTheKey);
})();
