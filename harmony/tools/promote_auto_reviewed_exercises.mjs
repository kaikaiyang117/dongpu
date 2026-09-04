import { readFile, writeFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const toolDir = dirname(fileURLToPath(import.meta.url));
const harmonyDir = resolve(toolDir, '..');
const generatedPath = join(harmonyDir, 'data/generated/exercise_localization_candidates.zh-CN.json');
const localizationPath = join(harmonyDir, 'data/exercise_localization.zh-CN.json');
const generated = JSON.parse(await readFile(generatedPath, 'utf8'));
const localization = JSON.parse(await readFile(localizationPath, 'utf8'));
const dryRun = process.argv.includes('--dry-run');
const result = { add: [], overwrite: [], approved: [], conflicts: [], skipped: [] };

for (const item of Object.values(generated)) {
  if (item.qualityGrade !== 'auto_reviewed' || !item.candidate) continue;
  const existing = localization[item.id];
  if (existing?.status === 'approved') { result.approved.push(item.id); continue; }
  if (existing?.status === 'reviewed') { result.skipped.push(item.id); continue; }
  if (existing !== undefined && existing.status !== 'raw') { result.skipped.push(item.id); continue; }
  if (existing?.manual === true || existing?.source?.startsWith('manual')) { result.skipped.push(item.id); continue; }
  const entry = {
    nameZh: item.candidate,
    aliasesZh: [],
    status: 'reviewed',
    source: item.translationMethod ?? 'structured-parser+rules',
    confidence: item.translationConfidence ?? item.confidence,
    note: '自动质量分级为 auto_reviewed，待人工抽查。'
  };
  result.add.push(item.id);
  if (!dryRun) localization[item.id] = entry;
}

console.log('准备 Promote：');
console.log(`将新增：${result.add.length}`);
console.log(`将覆盖：${result.overwrite.length}`);
console.log(`已存在 approved：${result.approved.length}`);
console.log(`冲突：${result.conflicts.length}`);
console.log(`跳过：${result.skipped.length}`);
if (!dryRun) {
  await writeFile(localizationPath, `${JSON.stringify(localization, null, 2)}\n`);
  console.log(`Promoted ${result.add.length} auto_reviewed entries as reviewed; approved status was never assigned.`);
} else {
  console.log('dry-run：未修改 formal localization。');
}
