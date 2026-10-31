// Approval preview only: composite a code-native radial halo behind the approved v3 GIF.
const path = require('node:path');
const assert = require('node:assert/strict');
const sharp = require('sharp');
sharp.concurrency(1);
sharp.cache(false);
const approved = path.resolve(__dirname, '../preview-v3');
const lowerShadow = process.argv.includes('--lower-shadow');
const largeSoft = lowerShadow || process.argv.includes('--large-soft');
const outputDir = lowerShadow ? path.resolve(__dirname, '../preview-v6')
  : largeSoft ? path.resolve(__dirname, '../preview-v5') : __dirname;
const size = 320, canvas = largeSoft ? 480 : 400, inset = (canvas - size) / 2;
const bg = [16, 17, 20];
const ease = value => {
  const x = Math.max(0, Math.min(1, value));
  return x * x * (3 - 2 * x);
};
const blend = (a, b, amount) => a.map((value, c) => value * (1 - amount) + b[c] * amount);

async function main() {
  const gif = path.join(approved, 'flame-preview-v3.gif');
  const metadata = await sharp(gif, {animated: true}).metadata();
  assert(metadata.width === size && metadata.pageHeight === size && metadata.pages === 300);
  assert(metadata.delay.every(delay => delay === 20));
  const pixels = await sharp(gif, {animated: true}).removeAlpha().raw().toBuffer();
  assert(pixels.length === size * size * 3 * metadata.pages);

  // Reconstruct only alpha from the unchanged authored artwork. Character RGB comes from v3.
  const source = path.join(approved, 'source-two-states.png');
  const image = await sharp(source).metadata();
  const masks = [];
  const shadowMasks = [];
  const bodyBounds = [];
  for (let state = 0; state < 2; state++) {
    const left = Math.round(state * image.width / 2);
    const rgba = await sharp(source).extract({left, top: 0,
      width: Math.round((state + 1) * image.width / 2) - left, height: image.height,
    }).resize(size, size).ensureAlpha().raw().toBuffer();
    const alpha = new Uint8Array(size * size);
    // The approved v3 render registered both states with dx=0, dy=1.
    for (let y = 1; y < size; y++) for (let x = 0; x < size; x++) {
      alpha[y * size + x] = rgba[((y - 1) * size + x) * 4 + 3];
    }
    masks.push(alpha);
    if (lowerShadow) {
      const blurred = await sharp(Buffer.from(alpha), {raw: {width: size, height: size, channels: 1}})
        .blur(7).greyscale().raw().toBuffer();
      assert(blurred.length === size * size);
      shadowMasks.push(blurred);
    }
    let top = size, bottom = 0;
    for (let y = 0; y < size; y++) for (let x = 0; x < size; x++) {
      if (alpha[y * size + x] >= 128) { top = Math.min(top, y); bottom = Math.max(bottom, y); }
    }
    assert(bottom > top);
    bodyBounds.push({top, bottom});
  }

  const cover = new Float32Array(canvas * canvas);
  const center = new Float32Array(canvas * canvas);
  const bloom = new Float32Array(canvas * canvas);
  for (let y = 0; y < canvas; y++) for (let x = 0; x < canvas; x++) {
    const p = y * canvas + x;
    const radius = Math.hypot(x + 0.5 - canvas / 2, y + 0.5 - canvas / 2);
    cover[p] = 1 - ease((radius - (largeSoft ? 175 : 155)) / (largeSoft ? 55 : 18));
    center[p] = Math.max(0, 1 - Math.pow(radius / (largeSoft ? 205 : 165), 1.6));
    bloom[p] = 1 - ease((radius - (largeSoft ? 155 : 145)) / (largeSoft ? 80 : 50));
  }

  const frames = [];
  let maxOpaqueCharacterDifference = 0;
  let maxBelowCutoffHaloDifference = 0;
  let maxVisibleShadowOpacity = 0;
  let maxInitialShadowOpacity = 0;
  const cutoffRange = [Infinity, -Infinity];
  for (let frame = 0; frame < metadata.pages; frame++) {
    const t = frame / 50;
    const light = t < 2.4 ? ease(t / 2.4) : t < 4.4 ? 1 : 1 - ease((t - 4.4) / 1.6);
    const smile = ease((light - 0.25) / 0.75);
    const phase = 2 * Math.PI * t / 6;
    const scaleX = 1 + Math.sin(phase) * 0.012;
    const scaleY = 1 - Math.sin(phase) * 0.018;
    const offsetY = -2.2 * (1 - Math.cos(phase));
    const baseTop = bodyBounds[0].top * (1 - smile) + bodyBounds[1].top * smile;
    const baseBottom = bodyBounds[0].bottom * (1 - smile) + bodyBounds[1].bottom * smile;
    const bottomBoundary = baseTop + (baseBottom - baseTop) * (lowerShadow ? 0.92 : 2 / 3);
    const cutoffY = (bottomBoundary - size * 0.6) * scaleY + size * 0.6 + offsetY + inset;
    cutoffRange[0] = Math.min(cutoffRange[0], cutoffY);
    cutoffRange[1] = Math.max(cutoffRange[1], cutoffY);
    const stage = light < 0.6 ? ease(light / 0.6) : ease((light - 0.6) / 0.4);
    const inner = light < 0.6 ? blend([104, 28, 40], [229, 80, 45], stage)
      : blend([229, 80, 45], [255, 230, 168], stage);
    const outer = light < 0.6 ? blend([94, 22, 38], [195, 35, 42], stage)
      : blend([195, 35, 42], [245, 120, 84], stage);
    const frameOffset = frame * size * size * 3;
    const previousBg = [pixels[frameOffset], pixels[frameOffset + 1], pixels[frameOffset + 2]];
    const output = Buffer.alloc(canvas * canvas * 3);
    for (let y = 0; y < canvas; y++) {
      // Fade before the requested bottom boundary, following the existing body motion.
      const feather = lowerShadow ? 64 : 96;
      const lowerFade = largeSoft ? 1 - ease((y - (cutoffY - feather)) / feather) : 1;
      const cy = y - inset;
      const sy = (cy - size * 0.6 - offsetY) / scaleY + size * 0.6;
      const y0 = Math.floor(sy), fy = sy - y0;
      const shadowY = (cy - 6 - size * 0.6 - offsetY) / scaleY + size * 0.6;
      const shadowY0 = Math.floor(shadowY), shadowFy = shadowY - shadowY0;
      for (let x = 0; x < canvas; x++) {
        const p = y * canvas + x;
        const cx = x - inset;
        const sx = (cx - size * 0.5) / scaleX + size * 0.5;
        const x0 = Math.floor(sx), fx = sx - x0;
        const inside = cx >= 0 && cx < size && cy >= 0 && cy < size;
        let alpha = 0;
        if (inside && x0 >= 0 && y0 >= 0 && x0 + 1 < size && y0 + 1 < size) {
          const i = y0 * size + x0;
          const sample = index => masks[0][index] * (1 - smile) + masks[1][index] * smile;
          const top = sample(i) * (1 - fx) + sample(i + 1) * fx;
          const bottom = sample(i + size) * (1 - fx) + sample(i + size + 1) * fx;
          alpha = (top * (1 - fy) + bottom * fy) / 255;
        }
        let shadowOpacity = 0;
        if (lowerShadow && x0 >= 0 && shadowY0 >= 0 && x0 + 1 < size && shadowY0 + 1 < size) {
          const i = shadowY0 * size + x0;
          const sample = index => shadowMasks[0][index] * (1 - smile) + shadowMasks[1][index] * smile;
          const top = sample(i) * (1 - fx) + sample(i + 1) * fx;
          const bottom = sample(i + size) * (1 - fx) + sample(i + size + 1) * fx;
          shadowOpacity = (top * (1 - shadowFy) + bottom * shadowFy) / 255 * 0.12 * light;
          maxVisibleShadowOpacity = Math.max(maxVisibleShadowOpacity, shadowOpacity * (1 - alpha));
          if (frame === 0) maxInitialShadowOpacity = Math.max(maxInitialShadowOpacity, shadowOpacity);
        }
        for (let c = 0; c < 3; c++) {
          const glow = bg[c] + (outer[c] - bg[c]) * bloom[p] *
            (largeSoft ? 0.02 + 0.08 * light : 0.04 + 0.16 * light);
          const color = outer[c] * (1 - center[p]) + inner[c] * center[p];
          const fullHalo = glow + (color - glow) * cover[p] *
            (largeSoft ? 0.10 + 0.30 * light : 0.23 + 0.62 * light);
          const halo = bg[c] + (fullHalo - bg[c]) * lowerFade;
          if (largeSoft && y >= cutoffY) maxBelowCutoffHaloDifference = Math.max(
            maxBelowCutoffHaloDifference, Math.abs(halo - bg[c]));
          // The soft drop shadow sits behind the character; its facial pixels remain untouched.
          const shadedHalo = halo * (1 - shadowOpacity) + [4, 3, 6][c] * shadowOpacity;
          let value = shadedHalo;
          if (inside) {
            const existing = pixels[frameOffset + (cy * size + cx) * 3 + c];
            value = existing + (shadedHalo - previousBg[c]) * (1 - alpha);
            if (alpha > 0.999) maxOpaqueCharacterDifference = Math.max(
              maxOpaqueCharacterDifference, Math.abs(Math.round(value) - existing));
          }
          output[p * 3 + c] = Math.max(0, Math.min(255, Math.round(value)));
        }
      }
    }
    frames.push(output);
  }
  assert(maxOpaqueCharacterDifference <= 1, 'Do not change the approved character.');
  if (largeSoft) assert(maxBelowCutoffHaloDifference === 0, 'No halo is allowed below the chosen bottom boundary.');
  if (lowerShadow) {
    assert(maxInitialShadowOpacity === 0 && maxVisibleShadowOpacity > 0 && maxVisibleShadowOpacity <= 0.12);
  }
  const haloPoint = (frame, x, y) => frames[frame].subarray((y * canvas + x) * 3, (y * canvas + x) * 3 + 3);
  const dim = [...haloPoint(0, canvas / 2, 53)], bright = [...haloPoint(150, canvas / 2, 53)];
  assert(bright.reduce((a, b) => a + b) > dim.reduce((a, b) => a + b) * 1.5);
  const belowMouthRGB = [...haloPoint(150, 70, 300)];
  if (lowerShadow) assert(belowMouthRGB.reduce((a, b) => a + b) > bg.reduce((a, b) => a + b) + 10,
    'The halo should still be visible below mouth height.');
  for (const frame of [0, 150]) {
    if (largeSoft) {
      assert.deepEqual([...haloPoint(frame, 70, 145)], [...haloPoint(frame, canvas - 71, 145)],
        'The upper halo must remain symmetric while the bottom is masked.');
    } else {
      assert.deepEqual([...haloPoint(frame, 200, 35)], [...haloPoint(frame, 35, 200)], 'The halo must be circular.');
    }
  }
  let seam = 0;
  for (let i = 0; i < frames[0].length; i++) seam += Math.abs(frames[0][i] - frames.at(-1)[i]);
  const meanLoopSeamDifference = seam / frames[0].length;
  assert(meanLoopSeamDifference < 1);
  for (const [name, frame] of [['preview-dim.png', 0], ['preview-smile.png', 150]]) {
    await sharp(frames[frame], {raw: {width: canvas, height: canvas, channels: 3}})
      .png().toFile(path.join(outputDir, name));
  }
  const file = path.join(outputDir, lowerShadow ? 'flame-preview-v6-halo-shadow.gif'
    : largeSoft ? 'flame-preview-v5-soft-halo.gif' : 'flame-preview-v4-halo.gif');
  await sharp(Buffer.concat(frames), {
    raw: {width: canvas, height: canvas * frames.length, channels: 3, pageHeight: canvas},
  }).gif({loop: 0, delay: metadata.delay, colours: 256, dither: 0, effort: 7}).toFile(file);
  const result = await sharp(file, {animated: true}).metadata();
  assert(result.pages === 300 && result.delay.every(delay => delay === 20) && result.loop === 0);
  console.log(JSON.stringify({file, width: canvas, height: canvas, frames: result.pages,
    durationMs: result.delay.reduce((a, b) => a + b), fps: 50, haloDimRGB: dim,
    haloBrightRGB: bright, maxOpaqueCharacterDifference,
    haloRadius: largeSoft ? 205 : 165, maxDiscOpacity: largeSoft ? 0.40 : 0.85,
    lowerThirdMask: largeSoft && !lowerShadow,
    hiddenBottomFraction: lowerShadow ? 0.08 : largeSoft ? 1 / 3 : 0,
    subtleShadow: lowerShadow, maxVisibleShadowOpacity: Number(maxVisibleShadowOpacity.toFixed(4)),
    maxInitialShadowOpacity, belowMouthRGB,
    cutoffRange: cutoffRange.map(value => Number(value.toFixed(2))),
    maxBelowCutoffHaloDifference,
    meanLoopSeamDifference: Number(meanLoopSeamDifference.toFixed(4)), previewOnly: true}, null, 2));
}
main().catch(error => {console.error(error); process.exitCode = 1;});
