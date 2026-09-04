import { readFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const toolDir = dirname(fileURLToPath(import.meta.url));
const harmonyDir = resolve(toolDir, '..');
const generatedPath = join(harmonyDir, 'data/generated/exercise_localization_candidates.zh-CN.json');
const candidates = JSON.parse(await readFile(generatedPath, 'utf8'));
const tokenStats = new Map();

for (const item of Object.values(candidates)) {
  for (const token of item.unknownTokens ?? []) {
    const stat = tokenStats.get(token) ?? { count: 0, exampleIds: [], exampleNames: [] };
    stat.count += 1;
    if (stat.exampleIds.length < 3) {
      stat.exampleIds.push(item.id);
      stat.exampleNames.push(item.nameEn);
    }
    tokenStats.set(token, stat);
  }
}

console.log('token\tcount\texampleIds\texampleNames');
for (const [token, stat] of [...tokenStats.entries()].sort((left, right) => right[1].count - left[1].count)) {
  console.log(`${token}\t${stat.count}\t${stat.exampleIds.join(',')}\t${stat.exampleNames.join(' | ')}`);
}
