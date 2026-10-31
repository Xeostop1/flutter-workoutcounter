// Approval preview only. Never writes app assets, Flutter code, or APKs.
const path = require('node:path');
const assert = require('node:assert/strict');
const sharp = require('sharp');
sharp.concurrency(1);
sharp.cache(false);

const size = 320;
const fps = 50;
const seconds = 6;
const bg = [16, 17, 20];
const source = path.join(__dirname, 'source-two-states.png');
const ease = x => {
  x = Math.max(0, Math.min(1, x));
  return x * x * (3 - 2 * x);
};

async function main() {
  const metadata = await sharp(source).metadata();
  assert(metadata.hasAlpha);
  const states = [];
  const registration = [];
  for (let state = 0; state < 2; state++) {
    const left = Math.round(state * metadata.width / 2);
    const rgba = await sharp(source).extract({left, top: 0,
      width: Math.round((state + 1) * metadata.width / 2) - left,
      height: metadata.height,
    }).resize(size, size).ensureAlpha().raw().toBuffer();
    let count = 0, sumX = 0, sumY = 0;
    for (let y = Math.floor(size * 0.4); y < size * 0.62; y++) {
      for (let x = Math.floor(size * 0.25); x < size * 0.75; x++) {
        if (x > size * 0.45 && x < size * 0.55) continue; // Exclude the smile.
        const i = (y * size + x) * 4;
        if (rgba[i] < 100 && rgba[i + 1] < 80 && rgba[i + 2] < 65 && rgba[i + 3] > 220) {
          count++; sumX += x; sumY += y;
        }
      }
    }
    assert(count > 100 && count < 3000, 'Both eye anchors must be identifiable.');
    const dx = Math.round(size * 0.5 - sumX / count);
    const dy = Math.round(size * 0.55 - sumY / count);
    registration.push({state, dx, dy, eyePixels: count});
    const rgb = Buffer.alloc(size * size * 3);
    for (let y = 0; y < size; y++) {
      for (let x = 0; x < size; x++) {
        const sx = x - dx, sy = y - dy;
        const valid = sx >= 0 && sx < size && sy >= 0 && sy < size;
        const input = (sy * size + sx) * 4;
        const alpha = valid ? rgba[input + 3] / 255 : 0;
        for (let c = 0; c < 3; c++) {
          rgb[(y * size + x) * 3 + c] = Math.round(
            (valid ? rgba[input + c] : 0) * alpha + bg[c] * (1 - alpha));
        }
      }
    }
    states.push(rgb);
  }

  const frames = [];
  const lightLevels = [];
  for (let frame = 0; frame < fps * seconds; frame++) {
    const t = frame / fps;
    const light = t < 2.4 ? ease(t / 2.4) : t < 4.4 ? 1 : 1 - ease((t - 4.4) / 1.6);
    const smile = ease((light - 0.25) / 0.75);
    const opacity = 0.8 + light * 0.2;
    const phase = 2 * Math.PI * t / seconds;
    const scaleX = 1 + Math.sin(phase) * 0.012;
    const scaleY = 1 - Math.sin(phase) * 0.018;
    const offsetY = -2.2 * (1 - Math.cos(phase));
    const mixed = Buffer.alloc(states[0].length);
    for (let i = 0; i < mixed.length; i++) {
      mixed[i] = Math.round(states[0][i] * (1 - smile) + states[1][i] * smile);
    }
    const output = Buffer.alloc(mixed.length);
    let totalLight = 0;
    // Bilinear subpixel sampling: continuous motion, not integer pixel jumps.
    for (let y = 0; y < size; y++) {
      const sy = (y - size * 0.6 - offsetY) / scaleY + size * 0.6;
      const y0 = Math.floor(sy), fy = sy - y0;
      for (let x = 0; x < size; x++) {
        const sx = (x - size * 0.5) / scaleX + size * 0.5;
        const x0 = Math.floor(sx), fx = sx - x0;
        const valid = x0 >= 0 && y0 >= 0 && x0 + 1 < size && y0 + 1 < size;
        for (let c = 0; c < 3; c++) {
          let color = bg[c];
          if (valid) {
            const p = (y0 * size + x0) * 3 + c;
            const a = mixed[p] * (1 - fx) + mixed[p + 3] * fx;
            const b = mixed[p + size * 3] * (1 - fx) + mixed[p + size * 3 + 3] * fx;
            color = a * (1 - fy) + b * fy;
          }
          const value = Math.round(bg[c] + (color - bg[c]) * opacity);
          output[(y * size + x) * 3 + c] = value;
          totalLight += value;
        }
      }
    }
    lightLevels.push(totalLight);
    frames.push(output);
  }
  assert(Math.max(...lightLevels) > lightLevels[0] * 1.2, 'The brightening must be measurable.');
  let seamDifference = 0;
  for (let i = 0; i < frames[0].length; i++) {
    seamDifference += Math.abs(frames[0][i] - frames.at(-1)[i]);
  }
  const meanSeamDifference = seamDifference / frames[0].length;
  assert(meanSeamDifference < 1, 'The loop boundary must not visibly jump.');
  const whiteGlints = [110, 182].map(left => {
    let count = 0;
    for (let y = 159; y < 187; y++) for (let x = left; x < left + 28; x++) {
      const p = (y * size + x) * 3;
      if (frames[150][p] > 215 && frames[150][p + 1] > 215 && frames[150][p + 2] > 215) count++;
    }
    return count;
  });
  assert(whiteGlints.every(count => count > 5), 'Both eyes must have visible white glints.');
  const png = raw => sharp(raw, {raw: {width: size, height: size, channels: 3}}).png();
  await png(frames[0]).toFile(path.join(__dirname, 'preview-dim.png'));
  await png(frames[150]).toFile(path.join(__dirname, 'preview-smile.png'));
  const file = path.join(__dirname, 'flame-preview-v3.gif');
  await sharp(Buffer.concat(frames), {
    raw: {width: size, height: size * frames.length, channels: 3, pageHeight: size},
  }).gif({loop: 0, delay: frames.map(() => 1000 / fps), colours: 128, dither: 0, effort: 7}).toFile(file);
  const result = await sharp(file, {animated: true}).metadata();
  const durationMs = result.delay.reduce((a, b) => a + b, 0);
  assert(durationMs === seconds * 1000 && result.loop === 0);
  assert(result.delay.every(delay => delay === 20), 'Every preview frame must have an explicit delay.');
  const check = {file, width: size, height: size, frames: result.pages,
    targetFps: fps, durationMs, minDelayMs: Math.min(...result.delay),
    maxDelayMs: Math.max(...result.delay), registration,
    whiteGlintPixelsPerEye: whiteGlints, meanLoopSeamDifference: Number(meanSeamDifference.toFixed(4)),
    brightnessRatio: Number((Math.max(...lightLevels) / lightLevels[0]).toFixed(3)),
    previewOnly: true};
  console.log(JSON.stringify(check, null, 2));
}
main().catch(error => {console.error(error); process.exitCode = 1;});
