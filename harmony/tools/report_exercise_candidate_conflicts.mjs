import { readFile, writeFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const toolDir = dirname(fileURLToPath(import.meta.url));
const harmonyDir = resolve(toolDir, '..');
const generatedPath = join(harmonyDir, 'data/generated/exercise_localization_candidates.zh-CN.json');
const reportPath = join(harmonyDir, 'data/generated/exercise_candidate_conflicts.json');
const generated = JSON.parse(await readFile(generatedPath, 'utf8'));

function normalize(value) {
  return String(value ?? '').trim().replace(/\s+/g, '');
}

const index = new Map();
for (const item of Object.values(generated)) {
  const key = normalize(item.candidate);
  if (!key) continue;
  const entries = index.get(key) ?? [];
  entries.push({ id: item.id, nameEn: item.nameEn, candidate: item.candidate });
  index.set(key, entries);
}
const conflicts = [...index.entries()]
  .filter(([, entries]) => new Set(entries.map((entry) => entry.id)).size > 1)
  .map(([candidate, entries]) => ({ candidate, entries }));

await writeFile(reportPath, `${JSON.stringify(conflicts, null, 2)}\n`);
console.log(`candidate collisions: ${conflicts.length}`);
for (const conflict of conflicts.slice(0, 20)) {
  console.log(`${conflict.candidate}\t${conflict.entries.map((entry) => entry.id).join(',')}`);
}
