/**
 * MICROGAME: Drag to Target
 *
 * Objective: Drag the object to the target zone
 * Difficulty scaling:
 * - Tier 1: Large target, close distance
 * - Tier 2: Medium target, medium distance
 * - Tier 3: Small target, far distance
 * - Tier 4: Tiny target, very far, moving target
 */

(function() {
    let container = null;
    let draggable = null;
    let target = null;
    let isDragging = false;
    let dragOffsetX = 0;
    let dragOffsetY = 0;
    let hasWon = false;
    let targetSize = 0;
    let isMovingTarget = false;
    let targetVx = 0;
    let targetVy = 0;
    let targetX = 0;
    let targetY = 0;

    const dragToTarget = {
        id: 'dragToTarget',
        name: 'Drag to Target',
        instructions: 'DRAG TO TARGET!',

        difficultyTiers: [
            {
                tier: 1,
                timeLimitMs: 4000,
                parameters: {
                    targetSize: 150,
                    targetDistance: 200,
                    moving: false
                }
            },
            {
                tier: 2,
                timeLimitMs: 3500,
                parameters: {
                    targetSize: 100,
                    targetDistance: 300,
                    moving: false
                }
            },
            {
                tier: 3,
                timeLimitMs: 3000,
                parameters: {
                    targetSize: 70,
                    targetDistance: 350,
                    moving: false
                }
            },
            {
                tier: 4,
                timeLimitMs: 2500,
                parameters: {
                    targetSize: 50,
                    targetDistance: 250,
                    moving: true
                }
            }
        ],

        init(rootElement, params) {
            container = rootElement;
            hasWon = false;
            isDragging = false;
            targetSize = params.targetSize;
            isMovingTarget = params.moving;

            // Create target
            target = document.createElement('div');
            target.className = 'microgame-element';
            target.style.width = targetSize + 'px';
            target.style.height = targetSize + 'px';
            target.style.background = 'rgba(46, 204, 113, 0.3)';
            target.style.border = '5px dashed #2ecc71';
            target.style.borderRadius = '50%';

            targetX = 400 + params.targetDistance;
            targetY = 275;

            target.style.left = targetX + 'px';
            target.style.top = targetY + 'px';
            target.style.transform = 'translate(-50%, -50%)';

            if (isMovingTarget) {
                targetVx = 0.15;
                targetVy = 0.1;
            }

            container.appendChild(target);

            // Create draggable
            draggable = document.createElement('div');
            draggable.className = 'microgame-element clickable';
            draggable.style.width = '60px';
            draggable.style.height = '60px';
            draggable.style.background = '#3498db';
            draggable.style.border = '4px solid #fff';
            draggable.style.borderRadius = '50%';
            draggable.style.left = '400px';
            draggable.style.top = '275px';
            draggable.style.transform = 'translate(-50%, -50%)';
            draggable.style.cursor = 'grab';
            draggable.style.zIndex = '10';

            container.appendChild(draggable);
        },

        update(dt, timeRemaining) {
            if (hasWon) {
                return MicrogameResult.WIN;
            }

            // Move target if applicable
            if (isMovingTarget && target) {
                targetX += targetVx * dt * 0.1;
                targetY += targetVy * dt * 0.1;

                // Bounce
                if (targetX < targetSize / 2 || targetX > 800 - targetSize / 2) targetVx *= -1;
                if (targetY < targetSize / 2 || targetY > 550 - targetSize / 2) targetVy *= -1;

                target.style.left = targetX + 'px';
                target.style.top = targetY + 'px';
            }

            return MicrogameResult.ONGOING;
        },

        handleInput(event) {
            if (!draggable) return;

            const rect = container.getBoundingClientRect();

            if (event.type === 'mousedown') {
                const draggableRect = draggable.getBoundingClientRect();
                const mouseX = event.clientX;
                const mouseY = event.clientY;

                if (mouseX >= draggableRect.left && mouseX <= draggableRect.right &&
                    mouseY >= draggableRect.top && mouseY <= draggableRect.bottom) {
                    isDragging = true;
                    dragOffsetX = mouseX - draggableRect.left - draggableRect.width / 2;
                    dragOffsetY = mouseY - draggableRect.top - draggableRect.height / 2;
                    draggable.style.cursor = 'grabbing';
                }
            }

            if (event.type === 'mousemove' && isDragging) {
                const x = event.clientX - rect.left - dragOffsetX;
                const y = event.clientY - rect.top - dragOffsetY;

                draggable.style.left = x + 'px';
                draggable.style.top = y + 'px';

                // Check if in target
                checkTargetCollision(x, y);
            }

            if (event.type === 'mouseup') {
                isDragging = false;
                if (draggable) draggable.style.cursor = 'grab';
            }
        },

        cleanup() {
            if (draggable) {
                draggable.remove();
                draggable = null;
            }
            if (target) {
                target.remove();
                target = null;
            }
            container = null;
        }
    };

    function checkTargetCollision(x, y) {
        const distance = Math.sqrt(
            Math.pow(x - targetX, 2) +
            Math.pow(y - targetY, 2)
        );

        if (distance < targetSize / 2) {
            hasWon = true;
            target.style.background = 'rgba(46, 204, 113, 0.8)';
        }
    }

    MicrogameManager.register(dragToTarget);
})();
