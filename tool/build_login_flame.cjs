// Historical v2 exporter. Current app assets use export_approved_login_flame.cjs.
const path = require('node:path');
const assert = require('node:assert/strict');
const sharp = require('sharp');

sharp.concurrency(1);
sharp.cache(false);
const root = path.resolve(__dirname, '..');
const source = path.join(root, 'design/login-flame/source-spritesheet-cute-v2.png');
const output = path.join(root, 'design/login-flame/app-before-v6');
const size = 256;
const background = [16, 17, 20]; // The login surface; GIF has no smooth alpha.

async function main() {
  const metadata = await sharp(source).metadata();
  assert(metadata.hasAlpha, 'The authored sprite sheet must retain alpha.');
  const frames = [];
  for (let index = 0; index < 12; index++) {
    const col = index % 4;
    const row = Math.floor(index / 4);
    const left = Math.round(col * metadata.width / 4);
    const top = Math.round(row * metadata.height / 3);
    const rgba = await sharp(source).extract({
      left, top,
      width: Math.round((col + 1) * metadata.width / 4) - left,
      height: Math.round((row + 1) * metadata.height / 3) - top,
    }).resize(size, size).ensureAlpha().raw().toBuffer();
    // Register the authored eyes so row-to-row sprite offsets don't make the face jump.
    let count = 0, eyeX = 0, eyeY = 0;
    for (let y = Math.floor(size * 0.4); y < size * 0.85; y++) {
      for (let x = Math.floor(size * 0.2); x < size * 0.8; x++) {
        const p = (y * size + x) * 4;
        if (rgba[p] < 70 && rgba[p + 1] < 50 && rgba[p + 2] < 40 && rgba[p + 3] > 220) {
          count++; eyeX += x; eyeY += y;
        }
      }
    }
    assert(count > 100 && count < 2000, `Missing mascot eyes in frame ${index}`);
    const dx = Math.round(size * 0.5 - eyeX / count);
    const dy = Math.round(size * 0.7 - eyeY / count);
    const rgb = Buffer.alloc(size * size * 3);
    for (let y = 0; y < size; y++) {
      for (let x = 0; x < size; x++) {
        const sx = x - dx, sy = y - dy;
        const valid = sx >= 0 && sx < size && sy >= 0 && sy < size;
        const sourcePixel = (sy * size + sx) * 4;
        const alpha = valid ? rgba[sourcePixel + 3] / 255 : 0;
        for (let channel = 0; channel < 3; channel++) {
          rgb[(y * size + x) * 3 + channel] = Math.round(
            (valid ? rgba[sourcePixel + channel] : 0) * alpha + background[channel] * (1 - alpha));
        }
      }
    }
    frames.push(rgb);
  }
  await sharp(frames[5], { raw: { width: size, height: size, channels: 3 } })
    .png().toFile(path.join(output, 'login_flame_still.png'));

  const animation = [];
  const delays = [];
  const transition = (from, to, milliseconds, steps = 3) => {
    for (let step = 0; step < steps; step++) {
      const amount = step / steps;
      const pixels = Buffer.alloc(frames[from].length);
      for (let i = 0; i < pixels.length; i++) {
        pixels[i] = Math.round(frames[from][i] * (1 - amount) + frames[to][i] * amount);
      }
      animation.push(pixels);
      delays.push(milliseconds / steps);
    }
  };
  // Short ignition, then a longer lively flicker; softly return for the next loop.
  for (let index = 0; index < 4; index++) transition(index, index + 1, 300);
  for (let cycle = 0; cycle < 2; cycle++) {
    for (let index = 4; index < 12; index++) {
      transition(index, index === 11 ? 4 : index + 1, 180);
    }
  }
  transition(4, 0, 600, 6);
  const file = path.join(output, 'login_flame_ignite.gif');
  await sharp(Buffer.concat(animation), {
    raw: { width: size, height: size * animation.length, channels: 3, pageHeight: size },
  }).gif({ loop: 0, delay: delays, colours: 96, dither: 0, effort: 8 }).toFile(file);
  const result = await sharp(file, { animated: true }).metadata();
  assert(result.pages > 24 && result.loop === 0 && result.pageHeight === size);
  assert(result.delay.reduce((a, b) => a + b, 0) >= 4000);
  console.log(JSON.stringify({ file, width: result.width, height: result.pageHeight,
    frames: result.pages, durationMs: result.delay.reduce((a, b) => a + b, 0), loop: result.loop }));
}
main().catch(error => { console.error(error); process.exitCode = 1; });
