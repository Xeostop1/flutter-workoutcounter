// Package the approved v6 artwork for Flutter. No character/artwork regeneration.
const path = require('node:path');
const assert = require('node:assert/strict');
const sharp = require('sharp');
sharp.concurrency(1);
sharp.cache(false);
const root = path.resolve(__dirname, '..');
const source = path.join(root, 'design/login-flame/preview-v6/flame-preview-v6-halo-shadow.gif');
const output = path.join(root, 'assets/images/login_flame_approved.webp');
const poster = path.join(root, 'assets/images/login_flame_still.png');
const width = 480, sourceHeight = 480, height = 400;

async function main() {
  const metadata = await sharp(source, {animated: true}).metadata();
  assert(metadata.width === width && metadata.pageHeight === sourceHeight && metadata.pages === 300);
  assert(metadata.loop === 0 && metadata.delay.every(delay => delay === 20));
  const raw = await sharp(source, {animated: true}).removeAlpha().raw().toBuffer();
  assert(raw.length === width * sourceHeight * 3 * metadata.pages);
  const cropped = [];
  let maxDiscardedBackgroundDifference = 0;
  for (let frame = 0; frame < metadata.pages; frame++) {
    const offset = frame * width * sourceHeight * 3;
    cropped.push(raw.subarray(offset, offset + width * height * 3));
    for (let p = offset + width * height * 3; p < offset + width * sourceHeight * 3; p++) {
      maxDiscardedBackgroundDifference = Math.max(maxDiscardedBackgroundDifference,
        Math.abs(raw[p] - [16, 17, 20][p % 3]));
    }
  }
  assert(maxDiscardedBackgroundDifference <= 1, 'Only empty background may be removed.');
  await sharp(Buffer.concat(cropped), {
    raw: {width, height: height * metadata.pages, channels: 3, pageHeight: height},
  // Lossy delta frames leave visible rectangular trails in the faint halo.
  }).webp({lossless: true, effort: 5, loop: 0, delay: metadata.delay}).toFile(output);
  await sharp(cropped[150], {raw: {width, height, channels: 3}}).png().toFile(poster);
  const result = await sharp(output, {animated: true}).metadata();
  assert(result.width === width && result.pageHeight === height && result.loop === 0);
  assert(result.pages === metadata.pages && result.delay.every(delay => delay === 20));
  const decoded = await sharp(output, {animated: true}).removeAlpha().raw().toBuffer();
  assert(decoded.equals(Buffer.concat(cropped)), 'Every decoded pixel must match the approved artwork.');
  console.log(JSON.stringify({output, width, height, frames: result.pages,
    durationMs: result.delay.reduce((a, b) => a + b, 0), fps: 50,
    maxDiscardedBackgroundDifference, pixelExact: true}, null, 2));
}
main().catch(error => {console.error(error); process.exitCode = 1;});
