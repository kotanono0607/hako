// Desktop Mascot - Cat Animation Controller

// Constants
const SPRITE_SIZE = 64;
const BOX_WIDTH = 280 - 8; // minus border
const BOX_HEIGHT = 200 - 8; // minus border
const MOVE_SPEED = 2; // pixels per frame
const MOVE_INTERVAL = 50; // ms
const ANIMATION_INTERVAL = 150; // ms
const RANDOM_TURN_CHANCE = 0.01; // 1% per frame
const STOP_CHANCE = 0.005; // 0.5% per frame
const MIN_STOP_TIME = 1000; // ms
const MAX_STOP_TIME = 3000; // ms

// Animation frame sequence: 0 -> 1 -> 2 -> 1 -> 0 ...
const FRAME_SEQUENCE = [0, 1, 2, 1];

// Direction definitions
const DIRECTIONS = {
  down: { row: 0, dx: 0, dy: 1 },
  left: { row: 1, dx: -1, dy: 0 },
  right: { row: 2, dx: 1, dy: 0 },
  up: { row: 3, dx: 0, dy: -1 }
};

const DIRECTION_NAMES = ['down', 'left', 'right', 'up'];

// Cat state
const cat = {
  x: Math.floor((BOX_WIDTH - SPRITE_SIZE) / 2),
  y: Math.floor((BOX_HEIGHT - SPRITE_SIZE) / 2),
  direction: 'down',
  frameIndex: 0, // index in FRAME_SEQUENCE
  isMoving: true,
  element: null
};

// Initialize
function init() {
  cat.element = document.getElementById('cat');
  if (!cat.element) {
    console.error('Cat element not found');
    return;
  }

  // Set initial position
  updatePosition();
  updateSprite();

  // Start animation and movement loops
  setInterval(animationLoop, ANIMATION_INTERVAL);
  setInterval(movementLoop, MOVE_INTERVAL);
}

// Update cat's visual position
function updatePosition() {
  cat.element.style.left = `${cat.x}px`;
  cat.element.style.top = `${cat.y}px`;
}

// Update sprite frame
function updateSprite() {
  // Remove all direction and frame classes
  cat.element.classList.remove('down', 'left', 'right', 'up');
  cat.element.classList.remove('frame-0', 'frame-1', 'frame-2');

  // Add current direction and frame
  cat.element.classList.add(cat.direction);
  cat.element.classList.add(`frame-${FRAME_SEQUENCE[cat.frameIndex]}`);
}

// Animation loop - handles sprite animation
function animationLoop() {
  if (cat.isMoving) {
    // Advance to next frame in sequence
    cat.frameIndex = (cat.frameIndex + 1) % FRAME_SEQUENCE.length;
    updateSprite();
  }
}

// Get random direction
function getRandomDirection() {
  return DIRECTION_NAMES[Math.floor(Math.random() * DIRECTION_NAMES.length)];
}

// Get opposite direction (for boundary bouncing)
function getOppositeDirection(dir) {
  switch (dir) {
    case 'left': return 'right';
    case 'right': return 'left';
    case 'up': return 'down';
    case 'down': return 'up';
    default: return 'down';
  }
}

// Check if at boundary
function checkBoundary() {
  const dir = DIRECTIONS[cat.direction];
  const nextX = cat.x + dir.dx * MOVE_SPEED;
  const nextY = cat.y + dir.dy * MOVE_SPEED;

  if (nextX <= 0 && cat.direction === 'left') {
    return 'right';
  }
  if (nextX >= BOX_WIDTH - SPRITE_SIZE && cat.direction === 'right') {
    return 'left';
  }
  if (nextY <= 0 && cat.direction === 'up') {
    return 'down';
  }
  if (nextY >= BOX_HEIGHT - SPRITE_SIZE && cat.direction === 'down') {
    return 'up';
  }
  return null;
}

// Stop the cat for a random duration
function stopCat() {
  cat.isMoving = false;
  cat.frameIndex = 1; // Stand frame
  updateSprite();

  const stopDuration = MIN_STOP_TIME + Math.random() * (MAX_STOP_TIME - MIN_STOP_TIME);
  setTimeout(() => {
    cat.isMoving = true;
    // Maybe change direction after stopping
    if (Math.random() < 0.5) {
      cat.direction = getRandomDirection();
    }
  }, stopDuration);
}

// Movement loop - handles position updates
function movementLoop() {
  if (!cat.isMoving) {
    return;
  }

  // Random stop check
  if (Math.random() < STOP_CHANCE) {
    stopCat();
    return;
  }

  // Check boundary collision
  const newDir = checkBoundary();
  if (newDir) {
    cat.direction = newDir;
    updateSprite();
    return;
  }

  // Random direction change
  if (Math.random() < RANDOM_TURN_CHANCE) {
    cat.direction = getRandomDirection();
    updateSprite();
  }

  // Move in current direction
  const dir = DIRECTIONS[cat.direction];
  cat.x += dir.dx * MOVE_SPEED;
  cat.y += dir.dy * MOVE_SPEED;

  // Clamp position within bounds
  cat.x = Math.max(0, Math.min(BOX_WIDTH - SPRITE_SIZE, cat.x));
  cat.y = Math.max(0, Math.min(BOX_HEIGHT - SPRITE_SIZE, cat.y));

  updatePosition();
}

// Start when DOM is ready
document.addEventListener('DOMContentLoaded', init);
