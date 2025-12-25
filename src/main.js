// Desktop Mascot - Character Animation Controller

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

// Frame mapping for each direction
// Format: direction -> [left_foot, stand, right_foot]
const FRAME_MAP = {
  down:  ['frame_00.png', 'frame_01.png', 'frame_02.png'],
  left:  ['frame_03.png', 'frame_04.png', 'frame_05.png'],
  right: ['frame_06.png', 'frame_07.png', 'frame_08.png'],
  up:    ['frame_09.png', 'frame_10.png', 'frame_11.png']
};

// Animation frame sequence: 0 -> 1 -> 2 -> 1 -> 0 ...
const FRAME_SEQUENCE = [0, 1, 2, 1];

// Direction definitions
const DIRECTIONS = {
  down:  { dx: 0, dy: 1 },
  left:  { dx: -1, dy: 0 },
  right: { dx: 1, dy: 0 },
  up:    { dx: 0, dy: -1 }
};

const DIRECTION_NAMES = ['down', 'left', 'right', 'up'];

// Character state
const character = {
  x: Math.floor((BOX_WIDTH - SPRITE_SIZE) / 2),
  y: Math.floor((BOX_HEIGHT - SPRITE_SIZE) / 2),
  direction: 'down',
  frameIndex: 0, // index in FRAME_SEQUENCE
  isMoving: true,
  element: null
};

// Preload images
const imageCache = {};

function preloadImages() {
  for (const direction of DIRECTION_NAMES) {
    for (const frame of FRAME_MAP[direction]) {
      const img = new Image();
      img.src = `/src/assets/${frame}`;
      imageCache[frame] = img;
    }
  }
}

// Initialize
function init() {
  character.element = document.getElementById('character');
  if (!character.element) {
    console.error('Character element not found');
    return;
  }

  // Preload all images
  preloadImages();

  // Set initial position
  updatePosition();
  updateSprite();

  // Start animation and movement loops
  setInterval(animationLoop, ANIMATION_INTERVAL);
  setInterval(movementLoop, MOVE_INTERVAL);
}

// Update character's visual position
function updatePosition() {
  character.element.style.left = `${character.x}px`;
  character.element.style.top = `${character.y}px`;
}

// Update sprite frame
function updateSprite() {
  const frameIdx = FRAME_SEQUENCE[character.frameIndex];
  const frameName = FRAME_MAP[character.direction][frameIdx];
  character.element.style.backgroundImage = `url('/src/assets/${frameName}')`;
}

// Animation loop - handles sprite animation
function animationLoop() {
  if (character.isMoving) {
    // Advance to next frame in sequence
    character.frameIndex = (character.frameIndex + 1) % FRAME_SEQUENCE.length;
    updateSprite();
  }
}

// Get random direction
function getRandomDirection() {
  return DIRECTION_NAMES[Math.floor(Math.random() * DIRECTION_NAMES.length)];
}

// Check if at boundary
function checkBoundary() {
  const dir = DIRECTIONS[character.direction];
  const nextX = character.x + dir.dx * MOVE_SPEED;
  const nextY = character.y + dir.dy * MOVE_SPEED;

  if (nextX <= 0 && character.direction === 'left') {
    return 'right';
  }
  if (nextX >= BOX_WIDTH - SPRITE_SIZE && character.direction === 'right') {
    return 'left';
  }
  if (nextY <= 0 && character.direction === 'up') {
    return 'down';
  }
  if (nextY >= BOX_HEIGHT - SPRITE_SIZE && character.direction === 'down') {
    return 'up';
  }
  return null;
}

// Stop the character for a random duration
function stopCharacter() {
  character.isMoving = false;
  character.frameIndex = 1; // Stand frame
  updateSprite();

  const stopDuration = MIN_STOP_TIME + Math.random() * (MAX_STOP_TIME - MIN_STOP_TIME);
  setTimeout(() => {
    character.isMoving = true;
    // Maybe change direction after stopping
    if (Math.random() < 0.5) {
      character.direction = getRandomDirection();
    }
  }, stopDuration);
}

// Movement loop - handles position updates
function movementLoop() {
  if (!character.isMoving) {
    return;
  }

  // Random stop check
  if (Math.random() < STOP_CHANCE) {
    stopCharacter();
    return;
  }

  // Check boundary collision
  const newDir = checkBoundary();
  if (newDir) {
    character.direction = newDir;
    updateSprite();
    return;
  }

  // Random direction change
  if (Math.random() < RANDOM_TURN_CHANCE) {
    character.direction = getRandomDirection();
    updateSprite();
  }

  // Move in current direction
  const dir = DIRECTIONS[character.direction];
  character.x += dir.dx * MOVE_SPEED;
  character.y += dir.dy * MOVE_SPEED;

  // Clamp position within bounds
  character.x = Math.max(0, Math.min(BOX_WIDTH - SPRITE_SIZE, character.x));
  character.y = Math.max(0, Math.min(BOX_HEIGHT - SPRITE_SIZE, character.y));

  updatePosition();
}

// Start when DOM is ready
document.addEventListener('DOMContentLoaded', init);
