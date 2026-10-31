// Reproduce the existing two-color logo as Android paths, without redesigning it.
// Run from the project root with the bundled pngjs module on NODE_PATH.
const fs = require('node:fs');
const assert = require('node:assert/strict');
const { PNG } = require('pngjs');
const source = PNG.sync.read(fs.readFileSync('assets/icons/splash_1.png'));
assert.equal(source.width, 1152);
assert.equal(source.height, 1152);
const width = source.width;
const stride = width + 1;

function simplify(points, tolerance = 0.85) {
  if (points.length <= 2) return points;
  const [a, b] = [points[0], points[points.length - 1]];
  const dx = b[0] - a[0], dy = b[1] - a[1];
  const length = dx * dx + dy * dy;
  let farthest = 0, distance = 0;
  for (let i = 1; i < points.length - 1; i++) {
    const p = points[i];
    const t = length ? Math.max(0, Math.min(1,
      ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / length)) : 0;
    const d = Math.hypot(p[0] - a[0] - t * dx, p[1] - a[1] - t * dy);
    if (d > distance) { distance = d; farthest = i; }
  }
  return distance <= tolerance ? [a, b] : [
    ...simplify(points.slice(0, farthest + 1), tolerance).slice(0, -1),
    ...simplify(points.slice(farthest), tolerance),
  ];
}

function trace(kind) {
  const mask = new Uint8Array(width * source.height);
  const colors = new Map();
  for (let i = 0; i < mask.length; i++) {
    const [r, g, b, a] = source.data.subarray(i * 4, i * 4 + 4);
    mask[i] = a >= 128 && r >= 128 && (kind === 'white'
      ? g >= 128 && b >= 128 : g < 128) ? 1 : 0;
    if (mask[i]) {
      const color = '#' + [r, g, b].map(n => n.toString(16).padStart(2, '0')).join('');
      colors.set(color, (colors.get(color) || 0) + 1);
    }
  }
  const edges = new Map();
  function edge(x, y, tx, ty, dir) {
    const key = y * stride + x;
    if (!edges.has(key)) edges.set(key, []);
    edges.get(key).push({ to: ty * stride + tx, dir });
  }
  for (let y = 0; y < source.height; y++) {
    for (let x = 0; x < width; x++) {
      if (!mask[y * width + x]) continue;
      if (!y || !mask[(y - 1) * width + x]) edge(x, y, x + 1, y, 0);
      if (x === width - 1 || !mask[y * width + x + 1]) edge(x + 1, y, x + 1, y + 1, 1);
      if (y === source.height - 1 || !mask[(y + 1) * width + x]) edge(x + 1, y + 1, x, y + 1, 2);
      if (!x || !mask[y * width + x - 1]) edge(x, y + 1, x, y, 3);
    }
  }
  const paths = [];
  let pointsBefore = 0, pointsAfter = 0;
  while (edges.size) {
    const first = edges.keys().next().value;
    let key = first, direction = null;
    const points = [];
    do {
      points.push([key % stride, Math.floor(key / stride)]);
      const choices = edges.get(key);
      assert(choices && choices.length, 'Every outline must close');
      if (direction !== null) {
        const rank = [1, 0, 3, 2];
        choices.sort((a, b) => rank.indexOf((a.dir - direction + 4) % 4)
          - rank.indexOf((b.dir - direction + 4) % 4));
      }
      const next = choices.shift();
      if (!choices.length) edges.delete(key);
      direction = next.dir;
      key = next.to;
    } while (key !== first);
    pointsBefore += points.length;
    const split = points.reduce((best, p, i) =>
      Math.hypot(p[0] - points[0][0], p[1] - points[0][1]) >
      Math.hypot(points[best][0] - points[0][0], points[best][1] - points[0][1])
        ? i : best, 0);
    const reduced = [...simplify(points.slice(0, split + 1)).slice(0, -1),
      ...simplify([...points.slice(split), points[0]]).slice(0, -1)];
    pointsAfter += reduced.length;
    paths.push(reduced.map((p, i) => `${i ? 'L' : 'M'}${p[0]},${p[1]}`).join('') + 'Z');
  }
  assert(paths.length > 0 && pointsAfter > 20);
  return { color: [...colors].sort((a, b) => b[1] - a[1])[0][0],
    path: paths.join(''), outlines: paths.length, pointsBefore, pointsAfter };
}

const layers = [trace('white'), trace('orange')];
const xml = `<?xml version="1.0" encoding="utf-8"?>
<!-- Derived from assets/icons/splash_1.png; regenerate with tool/build_android_wordmark.cjs. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="288dp" android:height="288dp"
    android:viewportWidth="1152" android:viewportHeight="1152">
    <group android:name="wordmark" android:pivotX="576" android:pivotY="576"
        android:scaleX="0.68" android:scaleY="0.68">
${layers.map(p => `    <path android:fillColor="${p.color}" android:pathData="${p.path}" />`).join('\n')}
    </group>
</vector>
`;
process.stdout.write(JSON.stringify({xml, layers}));
