import { access, readFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';

const harmonyDir = resolve(new URL('..', import.meta.url).pathname);
const projectDir = resolve(harmonyDir, '..');
const datasetDir = join(projectDir, 'assets/vendor/exercises-dataset');
const rawfileDir = join(harmonyDir, 'entry/src/main/resources/rawfile');

const source = JSON.parse(await readFile(join(datasetDir, 'data/exercises.json'), 'utf8'));
const localization = JSON.parse(await readFile(join(harmonyDir, 'data/exercise_localization.zh-CN.json'), 'utf8'));
const metadata = JSON.parse(await readFile(join(harmonyDir, 'data/exercise_metadata_overrides.json'), 'utf8'));
const catalog = JSON.parse(await readFile(join(rawfileDir, 'exercise_catalog.json'), 'utf8'));

const difficulties = new Set(['beginner', 'intermediate', 'advanced', 'unknown']);
const mechanics = new Set(['compound', 'isolation', 'cardio', 'mobility', 'unknown']);
const forces = new Set(['push', 'pull', 'static', 'mixed', 'unknown']);
const movementPatterns = new Set([
  'horizontal_push', 'vertical_push', 'horizontal_pull', 'vertical_pull', 'squat', 'hinge', 'lunge',
  'carry', 'core_flexion', 'core_rotation', 'core_anti_extension', 'core_anti_rotation', 'cardio',
  'mobility', 'other'
]);
const statuses = new Set(['raw', 'auto', 'reviewed', 'approved']);
const sourceIds = new Set(source.map((item) => item.id));
const catalogIds = new Set(catalog.map((item) => item.id));

const invalidLocalizationIds = Object.keys(localization).filter((id) => !sourceIds.has(id));
const invalidMetadataIds = Object.keys(metadata).filter((id) => !sourceIds.has(id));
const approvedWithoutName = Object.entries(localization)
  .filter(([, item]) => item.status === 'approved' && !item.nameZh?.trim())
  .map(([id]) => id);
const invalidEnums = [];
const missingMedia = [];
const duplicateNames = new Map();

for (const item of catalog) {
  if (!difficulties.has(item.difficulty) || !mechanics.has(item.mechanic) || !forces.has(item.force) ||
    !movementPatterns.has(item.movementPattern) || !statuses.has(item.localizationStatus)) {
    invalidEnums.push(item.id);
  }
  if (item.nameZh?.trim()) {
    const ids = duplicateNames.get(item.nameZh) ?? [];
    ids.push(item.id);
    duplicateNames.set(item.nameZh, ids);
  }
  for (const path of [item.imagePath, item.motionPath]) {
    try {
      await access(join(rawfileDir, path));
    } catch (_) {
      missingMedia.push(`${item.id}:${path}`);
    }
  }
}

const duplicateNameEntries = [...duplicateNames.entries()].filter(([, ids]) => ids.length > 1);
const counts = { approved: 0, reviewed: 0, auto: 0, raw: 0 };
for (const item of catalog) {
  counts[item.localizationStatus] += 1;
}
const englishFallback = catalog.filter((item) => !item.nameZh?.trim()).length;

console.log(`总动作数：${source.length}`);
console.log(`中文动作数：${catalog.filter((item) => item.nameZh?.trim()).length}`);
console.log(`approved：${counts.approved}`);
console.log(`reviewed：${counts.reviewed}`);
console.log(`auto：${counts.auto}`);
console.log(`raw：${counts.raw}`);
console.log(`重复中文名称：${duplicateNameEntries.length}`);
console.log(`无法匹配动作：${invalidLocalizationIds.length + invalidMetadataIds.length}`);
console.log(`仍显示英文动作：${englishFallback}`);

const missingCatalogIds = source.filter((item) => !catalogIds.has(item.id)).map((item) => item.id);
if (invalidLocalizationIds.length || invalidMetadataIds.length || approvedWithoutName.length || invalidEnums.length ||
  missingMedia.length || catalog.length !== source.length || missingCatalogIds.length) {
  console.error(JSON.stringify({ invalidLocalizationIds, invalidMetadataIds, approvedWithoutName, invalidEnums, missingMedia,
    missingCatalogIds }, null, 2));
  process.exitCode = 1;
}
