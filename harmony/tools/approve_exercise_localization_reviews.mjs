import { readFile, writeFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const toolDir = dirname(fileURLToPath(import.meta.url));
const harmonyDir = resolve(toolDir, '..');
const reviewsPath = join(harmonyDir, 'data/exercise_localization_reviews.zh-CN.json');
const localizationPath = join(harmonyDir, 'data/exercise_localization.zh-CN.json');
const reviews = JSON.parse(await readFile(reviewsPath, 'utf8'));
const localization = JSON.parse(await readFile(localizationPath, 'utf8'));
let approved = 0;

for (const [id, review] of Object.entries(reviews)) {
  if (!review.finalApproval || !['accepted', 'modified'].includes(review.decision)) continue;
  const current = localization[id];
  if (current === undefined) throw new Error(`Cannot approve missing localization: ${id}`);
  if (current.status === 'approved') continue;
  if (current.status !== 'reviewed') {
    throw new Error(`Cannot approve ${id} before promotion to reviewed; current status=${current.status}`);
  }
  current.status = 'approved';
  approved += 1;
}

await writeFile(localizationPath, `${JSON.stringify(localization, null, 2)}\n`);
console.log(`Approved ${approved} final-reviewed localization entries.`);
