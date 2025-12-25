// Desktop Mascot - Character Animation Controller

// Constants
const SPRITE_SIZE = 64;
const SPEECH_DURATION = 3000; // セリフ表示時間（ms）
const BOX_WIDTH = 440 - 8; // minus border
const BOX_HEIGHT = 320 - 8; // minus border
const MOVE_SPEED = 1; // pixels per frame
const MOVE_INTERVAL = 50; // ms
const ANIMATION_INTERVAL = 150; // ms
const RANDOM_TURN_CHANCE = 0.01; // 1% per frame
const STOP_CHANCE = 0.005; // 0.5% per frame
const MIN_STOP_TIME = 1000; // ms
const MAX_STOP_TIME = 3000; // ms
const MIN_RANDOM_SPEECH_INTERVAL = 15000; // 最短15秒
const MAX_RANDOM_SPEECH_INTERVAL = 45000; // 最長45秒

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

// セリフリスト（クリック時）
const SPEECHES = [
  'こんにちは！',
  'なあに？',
  '遊んでくれるの？',
  'えへへ〜',
  'お腹すいた...',
  '今日もいい天気だね',
  'zzz...あ、起きてるよ！',
  'なでなでして〜',
  '一緒にいてくれてありがとう',
  'お仕事がんばってね！',
  '休憩も大事だよ？',
  'わーい！'
];

// 独り言リスト（自発的に話す）
const MONOLOGUES = [
  'ふぅ〜...',
  'んー？',
  'らんらん♪',
  'ぽかぽかだなぁ',
  'お散歩たのしい！',
  '...zzz...ハッ！',
  'きょろきょろ',
  'なんか楽しいこと\nないかなー',
  'おなかすいてきた...',
  'るるる〜♪',
  '今日もがんばるぞ！',
  'ねぇねぇ、見てる？',
  'えへへ、楽しいな〜',
  'そろそろおやつの時間？',
  'メリークリスマス！'
];

// Character state
const character = {
  x: Math.floor((BOX_WIDTH - SPRITE_SIZE) / 2),
  y: Math.floor((BOX_HEIGHT - SPRITE_SIZE) / 2),
  direction: 'down',
  frameIndex: 0, // index in FRAME_SEQUENCE
  isMoving: true,
  element: null
};

// Speech bubble state
let speechBubble = null;
let speechTimeout = null;

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
  speechBubble = document.getElementById('speech-bubble');

  if (!character.element) {
    console.error('Character element not found');
    return;
  }

  // Preload all images
  preloadImages();

  // Set initial position
  updatePosition();
  updateSprite();

  // Add click event for speech
  character.element.addEventListener('click', onCharacterClick);

  // Start animation and movement loops
  setInterval(animationLoop, ANIMATION_INTERVAL);
  setInterval(movementLoop, MOVE_INTERVAL);

  // Start random speech timer
  scheduleRandomSpeech();
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

// Get random speech
function getRandomSpeech() {
  return SPEECHES[Math.floor(Math.random() * SPEECHES.length)];
}

// Get random monologue
function getRandomMonologue() {
  return MONOLOGUES[Math.floor(Math.random() * MONOLOGUES.length)];
}

// Schedule next random speech
function scheduleRandomSpeech() {
  const interval = MIN_RANDOM_SPEECH_INTERVAL +
    Math.random() * (MAX_RANDOM_SPEECH_INTERVAL - MIN_RANDOM_SPEECH_INTERVAL);

  setTimeout(() => {
    // Only speak if not already speaking
    if (!speechTimeout) {
      const monologue = getRandomMonologue();
      showSpeech(monologue);
    }
    // Schedule next random speech
    scheduleRandomSpeech();
  }, interval);
}

// Show speech bubble
function showSpeech(text) {
  if (!speechBubble) return;

  // Clear existing timeout
  if (speechTimeout) {
    clearTimeout(speechTimeout);
  }

  // Stop character movement while speaking
  character.isMoving = false;
  character.frameIndex = 1; // Stand frame
  updateSprite();

  // Set text and position
  speechBubble.textContent = text;
  speechBubble.classList.remove('hidden');

  // Position above character
  const bubbleX = Math.max(5, Math.min(character.x - 20, BOX_WIDTH - 160));
  const bubbleY = Math.max(5, character.y - 50);
  speechBubble.style.left = `${bubbleX}px`;
  speechBubble.style.top = `${bubbleY}px`;

  // Auto hide after duration
  speechTimeout = setTimeout(hideSpeech, SPEECH_DURATION);
}

// Hide speech bubble
function hideSpeech() {
  if (!speechBubble) return;
  speechBubble.classList.add('hidden');

  // Resume character movement
  character.isMoving = true;
}

// Character click handler
function onCharacterClick(event) {
  event.stopPropagation();
  const speech = getRandomSpeech();
  showSpeech(speech);
}

// Start when DOM is ready
document.addEventListener('DOMContentLoaded', init);
