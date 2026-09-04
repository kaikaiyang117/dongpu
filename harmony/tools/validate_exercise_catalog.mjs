import { access, readFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const toolDir = dirname(fileURLToPath(import.meta.url));
const harmonyDir = resolve(toolDir, '..');
const projectDir = resolve(harmonyDir, '..');
const datasetDir = join(projectDir, 'assets/vendor/exercises-dataset');
const rawfileDir = join(harmonyDir, 'entry/src/main/resources/rawfile');
const generatedPath = join(harmonyDir, 'data/generated/exercise_localization_candidates.zh-CN.json');

const source = JSON.parse(await readFile(join(datasetDir, 'data/exercises.json'), 'utf8'));
const localization = JSON.parse(await readFile(join(harmonyDir, 'data/exercise_localization.zh-CN.json'), 'utf8'));
const metadata = JSON.parse(await readFile(join(harmonyDir, 'data/exercise_metadata_overrides.json'), 'utf8'));
const catalog = JSON.parse(await readFile(join(rawfileDir, 'exercise_catalog.json'), 'utf8'));
const generated = JSON.parse(await readFile(generatedPath, 'utf8'));

const difficulties = new Set(['beginner', 'intermediate', 'advanced', 'unknown']);
const mechanics = new Set(['compound', 'isolation', 'cardio', 'mobility', 'unknown']);
const forces = new Set(['push', 'pull', 'static', 'mixed', 'unknown']);
const movementPatterns = new Set([
  'horizontal_push', 'vertical_push', 'horizontal_pull', 'vertical_pull', 'squat', 'hinge', 'lunge',
  'carry', 'core_flexion', 'core_rotation', 'core_anti_extension', 'core_anti_rotation', 'cardio',
  'mobility', 'other'
]);
const statuses = new Set(['raw', 'auto', 'reviewed', 'approved']);
const variantTags = new Set([
  'wide_grip', 'narrow_grip', 'underhand_grip', 'overhand_grip', 'neutral_grip', 'single_arm',
  'double_arm', 'single_leg', 'double_leg', 'incline', 'decline', 'flat', 'standing', 'seated',
  'kneeling', 'bent_over', 'assisted', 'weighted', 'paused', 'explosive', 'other'
]);
const replacementGroups = new Set([
  'horizontal_chest_press', 'incline_chest_press', 'chest_fly', 'vertical_shoulder_press',
  'shoulder_raise', 'rear_delt_fly', 'vertical_back_pull', 'horizontal_back_pull', 'biceps_curl',
  'triceps_extension', 'quad_extension', 'hamstring_curl', 'leg_press', 'squat', 'hinge', 'lunge',
  'core_flexion', 'core_anti_extension', 'core_rotation', 'carry', 'cardio', 'mobility', 'other'
]);
const variantAliasTokens = [
  '单臂', '双臂', '单腿', '双腿', '宽握', '窄握', '反手', '正手', '对握', '上斜', '下斜',
  '平板', '跪姿', '站姿', '坐姿', '俯身', '辅助', '负重', '暂停', '爆发'
];
const sourceIds = new Set(source.map((item) => item.id));
const catalogIds = new Set(catalog.map((item) => item.id));
const generatedIds = new Set(Object.keys(generated));

function normalize(value) {
  return String(value ?? '').trim().toLocaleLowerCase().replace(/\s+/g, '');
}

function distinctIds(ids) {
  return [...new Set(ids)];
}

const invalidLocalizationIds = Object.keys(localization).filter((id) => !sourceIds.has(id));
const invalidMetadataIds = Object.keys(metadata).filter((id) => !sourceIds.has(id));
const malformedLocalization = [];
for (const [id, item] of Object.entries(localization)) {
  if (item.nameZh !== undefined && typeof item.nameZh !== 'string') {
    malformedLocalization.push(`${id}:nameZh`);
  }
  if (item.aliasesZh !== undefined && (!Array.isArray(item.aliasesZh) ||
    item.aliasesZh.some((alias) => typeof alias !== 'string' || alias.trim().length === 0))) {
    malformedLocalization.push(`${id}:aliasesZh`);
  }
}
const approvedWithoutName = Object.entries(localization)
  .filter(([, item]) => item.status === 'approved' && !item.nameZh?.trim())
  .map(([id]) => id);
const invalidEnums = [];
const approvedMetadataMissing = [];
const missingMedia = [];
const primaryNameIndex = new Map();
const aliasIndex = new Map();
const englishNameIndex = new Map();

function addIndex(index, key, id) {
  if (!key) return;
  const ids = index.get(key) ?? [];
  ids.push(id);
  index.set(key, ids);
}

for (const item of catalog) {
  if (!difficulties.has(item.difficulty) || !mechanics.has(item.mechanic) || !forces.has(item.force) ||
    !movementPatterns.has(item.movementPattern) || !statuses.has(item.localizationStatus) ||
    (item.variantTags ?? []).some((tag) => !variantTags.has(tag)) ||
    !replacementGroups.has(item.replacementGroup)) {
    invalidEnums.push(item.id);
  }
  if (item.localizationStatus === 'approved' &&
    (item.difficulty === 'unknown' || item.mechanic === 'unknown' || item.force === 'unknown' ||
      !Array.isArray(item.variantTags) || !replacementGroups.has(item.replacementGroup) ||
      typeof item.recommended !== 'boolean' || typeof item.recommendedForBeginner !== 'boolean' ||
      typeof item.gymEligible !== 'boolean' || item.contentReviewStatus !== 'approved' ||
      item.libraryVisible !== true)) {
    approvedMetadataMissing.push(item.id);
  }
  addIndex(primaryNameIndex, normalize(item.nameZh), item.id);
  addIndex(englishNameIndex, normalize(item.nameEn), item.id);
  for (const alias of item.aliasesZh ?? []) {
    addIndex(aliasIndex, normalize(alias), item.id);
  }
  for (const path of [item.imagePath, item.motionPath]) {
    try {
      await access(join(rawfileDir, path));
    } catch (_) {
      missingMedia.push(`${item.id}:${path}`);
    }
  }
}

const duplicatePrimaryNameZh = [...primaryNameIndex.entries()]
  .map(([name, ids]) => ({ name, ids: distinctIds(ids) }))
  .filter((entry) => entry.ids.length > 1);
const aliasToPrimaryConflicts = [];
for (const [alias, ids] of aliasIndex.entries()) {
  const aliasIds = distinctIds(ids);
  const primaryIds = distinctIds(primaryNameIndex.get(alias) ?? []);
  const conflictingIds = primaryIds.filter((id) => !aliasIds.includes(id));
  if (conflictingIds.length > 0) {
    aliasToPrimaryConflicts.push({ alias, aliasIds, primaryIds: conflictingIds });
  }
}
const aliasToAliasConflicts = [...aliasIndex.entries()]
  .map(([alias, ids]) => ({ alias, ids: distinctIds(ids) }))
  .filter((entry) => entry.ids.length > 1);
const englishNameConflicts = [...englishNameIndex.entries()]
  .map(([name, ids]) => ({ name, ids: distinctIds(ids) }))
  .filter((entry) => entry.ids.length > 1);
const possibleVariantAlias = [];
for (const item of catalog) {
  for (const alias of item.aliasesZh ?? []) {
    const token = variantAliasTokens.find((candidate) => alias.includes(candidate) && !item.nameZh.includes(candidate));
    if (token !== undefined) {
      possibleVariantAlias.push({ id: item.id, nameZh: item.nameZh, alias, token });
    }
  }
}

const unknownTokenEntries = Object.values(generated).filter((item) => (item.unknownTokens ?? []).length > 0);
const qualityGrades = new Set(['auto_reviewed', 'needs_review', 'needs_manual']);
const translationMethods = new Set(['structured-parser', 'structured-parser+rules', 'structured-parser+agent-review', 'manual', 'upstream-English']);
const generatedMetadataErrors = Object.values(generated).filter((item) => {
  const metadataCandidate = item.metadataCandidate ?? {};
  return !difficulties.has(metadataCandidate.difficulty ?? 'unknown') ||
    !mechanics.has(metadataCandidate.mechanic ?? 'unknown') ||
    !forces.has(metadataCandidate.force ?? 'unknown') ||
    !movementPatterns.has(metadataCandidate.movementPattern ?? 'other') ||
    !replacementGroups.has(metadataCandidate.replacementGroup ?? 'other') ||
    (metadataCandidate.variantTags ?? []).some((tag) => !variantTags.has(tag));
});
const generatedSchemaErrors = Object.values(generated).filter((item) =>
  typeof item.id !== 'string' || typeof item.nameEn !== 'string' || typeof item.candidate !== 'string' ||
  typeof item.translationConfidence !== 'number' || typeof item.translationMethod !== 'string' ||
  !Array.isArray(item.unknownTokens) || !Array.isArray(item.issues) || !qualityGrades.has(item.qualityGrade) ||
  item.metadataCandidate === undefined || !Array.isArray(item.metadataCandidate.variantTags));
const catalogQualityErrors = catalog.filter((item) =>
  typeof item.translationConfidence !== 'number' || !translationMethods.has(item.translationMethod) ||
  !qualityGrades.has(item.localizationQuality));
const generatedMissingIds = source.filter((item) => !generatedIds.has(item.id)).map((item) => item.id);
const generatedExtraIds = [...generatedIds].filter((id) => !sourceIds.has(id));
const variantLost = Object.values(generated).filter((item) => (item.issues ?? []).includes('variant_lost'));
const candidateCollisions = Object.values(generated).filter((item) => (item.issues ?? []).includes('candidate_collision'));

const counts = { approved: 0, reviewed: 0, auto: 0, raw: 0 };
for (const item of catalog) {
  if (counts[item.localizationStatus] !== undefined) counts[item.localizationStatus] += 1;
}
const missingCatalogIds = source.filter((item) => !catalogIds.has(item.id)).map((item) => item.id);
const englishFallback = catalog.filter((item) => !item.nameZh?.trim()).length;
const errors = {
  invalidLocalizationIds,
  invalidMetadataIds,
  malformedLocalization,
  approvedWithoutName,
  approvedMetadataMissing,
  invalidEnums,
  missingMedia,
  missingCatalogIds,
  duplicatePrimaryNameZh,
  aliasToPrimaryConflicts,
  aliasToAliasConflicts
  , generatedSchemaErrors
  , generatedMissingIds
  , generatedExtraIds
  , generatedMetadataErrors
  , catalogQualityErrors
};

console.log(`总动作数：${source.length}`);
console.log(`中文动作数：${catalog.filter((item) => item.nameZh?.trim()).length}`);
console.log(`approved：${counts.approved}`);
console.log(`reviewed：${counts.reviewed}`);
console.log(`auto：${counts.auto}`);
console.log(`raw：${counts.raw}`);
console.log(`重复中文主名称：${duplicatePrimaryNameZh.length}`);
console.log(`alias-primary 冲突：${aliasToPrimaryConflicts.length}`);
console.log(`alias-alias 冲突：${aliasToAliasConflicts.length}`);
console.log(`英文原名冲突（warning）：${englishNameConflicts.length}`);
console.log(`疑似 variant alias：${possibleVariantAlias.length}`);
console.log(`unknown tokens：${unknownTokenEntries.length}`);
console.log(`variant lost：${variantLost.length}`);
console.log(`candidate collisions：${candidateCollisions.length}`);
console.log(`全量 Generated：${generatedIds.size}`);
console.log(`无法匹配动作：${invalidLocalizationIds.length + invalidMetadataIds.length}`);
console.log(`仍显示英文动作：${englishFallback}`);

const hasErrors = Object.values(errors).some((entries) => entries.length > 0) || catalog.length !== source.length || generatedIds.size !== source.length;
if (hasErrors) {
  console.error(JSON.stringify({ ...errors, catalogLength: catalog.length, sourceLength: source.length }, null, 2));
  process.exitCode = 1;
} else {
  console.log('exercise catalog validation: PASS');
}
