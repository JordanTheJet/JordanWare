/**
 * MICROGAME: Catch the Falling
 *
 * Objective: Catch the falling objects with your basket
 * Difficulty scaling:
 * - Tier 1: Catch 2 items, slow fall
 * - Tier 2: Catch 3 items, medium fall
 * - Tier 3: Catch 4 items, fast fall
 * - Tier 4: Catch 5 items, very fast, smaller basket
 */

(function() {
    let container = null;
    let basket = null;
    let fallingItems = [];
    let basketX = 400;
    let caughtCount = 0;
    let requiredCatches = 0;
    let fallSpeed = 0;
    let basketWidth = 0;

    const catchTheFalling = {
        id: 'catchTheFalling',
        name: 'Catch the Falling',
        instructions: 'CATCH THEM ALL!',

        difficultyTiers: [
            {
                tier: 1,
                timeLimitMs: 5000,
                parameters: {
                    requiredCatches: 2,
                    fallSpeed: 0.2,
                    itemCount: 3,
                    basketWidth: 120
                }
            },
            {
                tier: 2,
                timeLimitMs: 4500,
                parameters: {
                    requiredCatches: 3,
                    fallSpeed: 0.3,
                    itemCount: 5,
                    basketWidth: 100
                }
            },
            {
                tier: 3,
                timeLimitMs: 4000,
                parameters: {
                    requiredCatches: 4,
                    fallSpeed: 0.4,
                    itemCount: 6,
                    basketWidth: 80
                }
            },
            {
                tier: 4,
                timeLimitMs: 3500,
                parameters: {
                    requiredCatches: 5,
                    fallSpeed: 0.5,
                    itemCount: 7,
                    basketWidth: 60
                }
            }
        ],

        init(rootElement, params) {
            container = rootElement;
            caughtCount = 0;
            requiredCatches = params.requiredCatches;
            fallSpeed = params.fallSpeed;
            basketWidth = params.basketWidth;
            basketX = 400;
            fallingItems = [];

            // Create basket
            basket = document.createElement('div');
            basket.className = 'microgame-element';
            basket.style.width = basketWidth + 'px';
            basket.style.height = '30px';
            basket.style.background = '#3498db';
            basket.style.border = '4px solid #fff';
            basket.style.borderRadius = '5px';
            basket.style.bottom = '30px';
            basket.style.left = (basketX - basketWidth / 2) + 'px';
            container.appendChild(basket);

            // Create counter
            const counter = document.createElement('div');
            counter.id = 'catch-counter';
            counter.style.position = 'absolute';
            counter.style.top = '20px';
            counter.style.left = '50%';
            counter.style.transform = 'translateX(-50%)';
            counter.style.fontSize = '32px';
            counter.style.color = '#fff';
            counter.style.fontWeight = 'bold';
            counter.textContent = `${caughtCount} / ${requiredCatches}`;
            container.appendChild(counter);

            // Create falling items
            for (let i = 0; i < params.itemCount; i++) {
                createFallingItem(i * 150);
            }
        },

        update(dt, timeRemaining) {
            // Update basket position
            basket.style.left = (basketX - basketWidth / 2) + 'px';

            // Update falling items
            fallingItems.forEach(item => {
                if (!item.caught) {
                    item.y += fallSpeed * dt;
                    item.element.style.top = item.y + 'px';

                    // Check catch
                    const basketTop = 550 - 30 - 30;
                    if (item.y >= basketTop && item.y <= basketTop + 40) {
                        const basketLeft = basketX - basketWidth / 2;
                        const basketRight = basketX + basketWidth / 2;

                        if (item.x >= basketLeft && item.x <= basketRight) {
                            item.caught = true;
                            item.element.style.display = 'none';
                            caughtCount++;

                            // Update counter
                            const counter = container.querySelector('#catch-counter');
                            if (counter) {
                                counter.textContent = `${caughtCount} / ${requiredCatches}`;
                            }
                        }
                    }

                    // Reset if missed
                    if (item.y > 550) {
                        item.y = -30;
                        item.x = Math.random() * 740 + 30;
                        item.element.style.left = item.x + 'px';
                        item.element.style.top = item.y + 'px';
                    }
                }
            });

            // Check win
            if (caughtCount >= requiredCatches) {
                return MicrogameResult.WIN;
            }

            return MicrogameResult.ONGOING;
        },

        handleInput(event) {
            if (event.type === 'mousemove') {
                const rect = container.getBoundingClientRect();
                basketX = Math.max(basketWidth / 2, Math.min(800 - basketWidth / 2, event.clientX - rect.left));
            }
        },

        cleanup() {
            if (basket) {
                basket.remove();
                basket = null;
            }
            fallingItems.forEach(item => item.element.remove());
            fallingItems = [];
            if (container) {
                container.innerHTML = '';
            }
            container = null;
        }
    };

    function createFallingItem(yOffset) {
        const item = document.createElement('div');
        item.className = 'microgame-element';
        item.style.width = '30px';
        item.style.height = '30px';
        item.style.background = '#f39c12';
        item.style.border = '3px solid #fff';
        item.style.borderRadius = '50%';

        const x = Math.random() * 740 + 30;
        const y = -30 - yOffset;

        item.style.left = x + 'px';
        item.style.top = y + 'px';

        container.appendChild(item);

        fallingItems.push({
            element: item,
            x: x,
            y: y,
            caught: false
        });
    }

    MicrogameManager.register(catchTheFalling);
})();
