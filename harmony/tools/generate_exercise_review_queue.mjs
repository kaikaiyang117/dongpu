import { readFile, writeFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const toolDir = dirname(fileURLToPath(import.meta.url));
const harmonyDir = resolve(toolDir, '..');
const generatedPath = join(harmonyDir, 'data/generated/exercise_localization_candidates.zh-CN.json');
const queuePath = join(harmonyDir, 'data/generated/exercise_review_queue.json');
const generated = JSON.parse(await readFile(generatedPath, 'utf8'));

function queueEntry(item) {
  return {
    id: item.id,
    nameEn: item.nameEn,
    candidate: item.candidate,
    confidence: item.confidence,
    issues: item.issues ?? [],
    metadataCandidate: item.metadataCandidate
  };
}

const queue = { needsReview: [], needsManual: [] };
for (const item of Object.values(generated)) {
  if (item.qualityGrade === 'needs_manual') queue.needsManual.push(queueEntry(item));
  if (item.qualityGrade === 'needs_review') queue.needsReview.push(queueEntry(item));
}
await writeFile(queuePath, `${JSON.stringify(queue, null, 2)}\n`);
console.log(`review queue: needs_review=${queue.needsReview.length}, needs_manual=${queue.needsManual.length}`);
