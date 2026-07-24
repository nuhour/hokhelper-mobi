// Procedural Web Audio API sound generator for HOK Hexagram Instrument interactions
let audioCtx: AudioContext | null = null;
let isMuted = false;

function getAudioContext(): AudioContext | null {
  if (isMuted) return null;
  if (!audioCtx) {
    const AudioContextClass = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
    if (AudioContextClass) {
      audioCtx = new AudioContextClass();
    }
  }
  if (audioCtx && audioCtx.state === 'suspended') {
    audioCtx.resume();
  }
  return audioCtx;
}

export function toggleAudioMute(muted?: boolean): boolean {
  if (muted !== undefined) {
    isMuted = muted;
  } else {
    isMuted = !isMuted;
  }
  return isMuted;
}

export function getIsMuted(): boolean {
  return isMuted;
}

/** Play a soft, resonant silver ring tick sound when hexagram instrument is rotated (柔软银环轻响) */
export function playCubeRotateTick() {
  const ctx = getAudioContext();
  if (!ctx) return;

  try {
    const now = ctx.currentTime;
    const osc = ctx.createOscillator();
    const oscHarmonic = ctx.createOscillator();
    const gain = ctx.createGain();

    // Pure metallic fundamental (880Hz - A5) & soft harmonic (1760Hz)
    osc.type = 'sine';
    osc.frequency.setValueAtTime(880 + Math.random() * 60, now);

    oscHarmonic.type = 'sine';
    oscHarmonic.frequency.setValueAtTime(1760 + Math.random() * 120, now);

    gain.gain.setValueAtTime(0.04, now);
    gain.gain.exponentialRampToValueAtTime(0.0005, now + 0.12);

    osc.connect(gain);
    oscHarmonic.connect(gain);
    gain.connect(ctx.destination);

    osc.start(now);
    oscHarmonic.start(now);
    osc.stop(now + 0.12);
    oscHarmonic.stop(now + 0.12);
  } catch {
    // Ignore audio errors
  }
}

/** Play soft metallic singing bowl & magic spellcasting sound when shaking fortune (柔软金属法器施法音效) */
export function playFortuneSpinSound() {
  const ctx = getAudioContext();
  if (!ctx) return;

  try {
    const now = ctx.currentTime;

    // 1. Soft Metallic Singing Bowl / Gong Base Resonance (384Hz & 576Hz overtones)
    const bowlFreqs = [216, 384, 576, 864];
    bowlFreqs.forEach((freq, idx) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, now);
      // Gentle pitch bend representing magical resonance spellcast
      osc.frequency.exponentialRampToValueAtTime(freq * 1.08, now + 1.2);
      osc.frequency.exponentialRampToValueAtTime(freq * 0.95, now + 2.4);

      const initGain = 0.08 / (idx + 1);
      gain.gain.setValueAtTime(0.001, now);
      gain.gain.linearRampToValueAtTime(initGain, now + 0.3);
      gain.gain.exponentialRampToValueAtTime(0.0005, now + 2.6);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(now);
      osc.stop(now + 2.6);
    });

    // 2. Soft Metallic Chime Shimmer (Soft bells shimmering as spell is cast)
    const chimePitches = [1046.50, 1318.51, 1567.98, 2093.00]; // C6, E6, G6, C7
    chimePitches.forEach((pitch, i) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = 'sine';
      const startTime = now + 0.2 + i * 0.35;
      osc.frequency.setValueAtTime(pitch, startTime);

      gain.gain.setValueAtTime(0.03, startTime);
      gain.gain.exponentialRampToValueAtTime(0.0002, startTime + 0.9);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(startTime);
      osc.stop(startTime + 0.9);
    });
  } catch {
    // Ignore audio errors
  }
}

/** Play a serene, heavenly metallic Tibetan chime when fortune result is revealed (法器大成金鸣) */
export function playFortuneChimeSound() {
  const ctx = getAudioContext();
  if (!ctx) return;

  try {
    const now = ctx.currentTime;
    // Soft Pentatonic Metallic Harmony: D5, F#5, A5, D6, F#6
    const pentatonic = [587.33, 739.99, 880.00, 1174.66, 1479.98];

    pentatonic.forEach((freq, idx) => {
      const osc = ctx.createOscillator();
      const oscOvertone = ctx.createOscillator();
      const gain = ctx.createGain();

      const startTime = now + idx * 0.09;

      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, startTime);

      // Soft metallic bell overtone (2.76x frequency multiplier gives bell-like timbre)
      oscOvertone.type = 'sine';
      oscOvertone.frequency.setValueAtTime(freq * 2.76, startTime);

      gain.gain.setValueAtTime(0.12, startTime);
      gain.gain.exponentialRampToValueAtTime(0.0001, startTime + 1.8);

      osc.connect(gain);
      oscOvertone.connect(gain);
      gain.connect(ctx.destination);

      osc.start(startTime);
      oscOvertone.start(startTime);
      osc.stop(startTime + 1.8);
      oscOvertone.stop(startTime + 1.8);
    });
  } catch {
    // Ignore audio errors
  }
}

/** Trigger haptic vibration feedback for mobile devices */
export function triggerHaptic(pattern: number | number[] = 30) {
  if (typeof window !== 'undefined' && window.navigator && window.navigator.vibrate) {
    try {
      window.navigator.vibrate(pattern);
    } catch {
      // Ignore vibration unsupported error
    }
  }
}
