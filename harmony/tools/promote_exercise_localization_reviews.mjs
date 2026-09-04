import { readFile, writeFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const toolDir = dirname(fileURLToPath(import.meta.url));
const harmonyDir = resolve(toolDir, '..');
const generatedPath = join(harmonyDir, 'data/generated/exercise_localization_candidates.zh-CN.json');
const reviewsPath = join(harmonyDir, 'data/exercise_localization_reviews.zh-CN.json');
const localizationPath = join(harmonyDir, 'data/exercise_localization.zh-CN.json');
const generated = JSON.parse(await readFile(generatedPath, 'utf8'));
const reviews = JSON.parse(await readFile(reviewsPath, 'utf8'));
const localization = JSON.parse(await readFile(localizationPath, 'utf8'));
const decisions = new Set(['pending', 'accepted', 'modified', 'rejected', 'needs_manual']);
let promoted = 0;

for (const [id, review] of Object.entries(reviews)) {
  if (!decisions.has(review.decision)) {
    throw new Error(`Invalid review decision for ${id}: ${review.decision}`);
  }
  if (review.decision !== 'accepted' && review.decision !== 'modified') {
    continue;
  }
  const candidate = generated[id];
  if (candidate === undefined) {
    throw new Error(`Review has no generated candidate: ${id}`);
  }
  const reviewedName = (review.reviewedName ?? candidate.candidate ?? '').trim();
  if (reviewedName.length === 0) {
    throw new Error(`Review has no usable reviewedName: ${id}`);
  }
  const aliasesZh = review.aliasesZh ?? [];
  if (!Array.isArray(aliasesZh) || aliasesZh.some((alias) => typeof alias !== 'string' || alias.trim().length === 0)) {
    throw new Error(`Invalid aliasesZh in review: ${id}`);
  }
  const normalizedAliases = aliasesZh.map((alias) => alias.trim());
  if (normalizedAliases.includes(reviewedName)) {
    throw new Error(`Review alias duplicates reviewedName: ${id}`);
  }
  const existing = localization[id];
  if (existing?.status === 'approved') {
    continue;
  }
  localization[id] = {
    nameZh: reviewedName,
    aliasesZh: normalizedAliases,
    status: 'reviewed',
    source: review.reviewedBy ? `dongpu-review:${review.reviewedBy}` : 'dongpu-review',
    note: review.note ?? ''
  };
  promoted += 1;
}

await writeFile(localizationPath, `${JSON.stringify(localization, null, 2)}\n`);
console.log(`Promoted ${promoted} reviewed localization entries; approved status was never assigned.`);
