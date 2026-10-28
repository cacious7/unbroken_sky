// Original PCM effects. Run: node engine/tools/generate_play_sounds.js
const fs = require('fs');
const path = require('path');
const target = path.resolve(__dirname, '../assets/sfx');
function wav(name, duration, sample) {
  const rate = 22050, count = Math.floor(rate * duration);
  const data = Buffer.alloc(44 + count * 2);
  data.write('RIFF'); data.writeUInt32LE(36 + count * 2, 4);
  data.write('WAVEfmt ', 8); data.writeUInt32LE(16, 16);
  data.writeUInt16LE(1, 20); data.writeUInt16LE(1, 22);
  data.writeUInt32LE(rate, 24); data.writeUInt32LE(rate * 2, 28);
  data.writeUInt16LE(2, 32); data.writeUInt16LE(16, 34);
  data.write('data', 36); data.writeUInt32LE(count * 2, 40);
  for (let i = 0; i < count; i++) {
    const value = Math.max(-1, Math.min(1, sample(i / rate)));
    data.writeInt16LE(Math.round(value * 32767), 44 + i * 2);
  }
  fs.writeFileSync(path.join(target, name + '.wav'), data);
}
wav('wind_gain', 0.38, t => [880, 1108.73, 1318.51].reduce((sum, frequency, index) => {
  const elapsed = t - index * 0.065;
  return sum + (elapsed < 0 ? 0 : Math.sin(2 * Math.PI * frequency * elapsed) *
    Math.exp(-elapsed * 17) * Math.min(elapsed / 0.008, 1) * 0.22);
}, 0));
let seed = 37;
wav('sand_step', 0.1, t => {
  seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
  return ((seed / 4294967296 - 0.5) * 0.35 + Math.sin(2 * Math.PI * 90 * t) * 0.14) *
    Math.exp(-t * 48) * Math.min(t / 0.004, 1);
});
