import { readFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const toolDir = dirname(fileURLToPath(import.meta.url));
const harmonyDir = resolve(toolDir, '..');
const catalogPath = join(harmonyDir, 'entry/src/main/resources/rawfile/exercise_catalog.json');
const localizationPath = join(harmonyDir, 'data/exercise_localization.zh-CN.json');
const generatedPath = join(harmonyDir, 'data/generated/exercise_localization_candidates.zh-CN.json');
const catalog = JSON.parse(await readFile(catalogPath, 'utf8'));
const localization = JSON.parse(await readFile(localizationPath, 'utf8'));
const generated = JSON.parse(await readFile(generatedPath, 'utf8'));
const candidateConflictPath = join(harmonyDir, 'data/generated/exercise_candidate_conflicts.json');
let candidateConflicts = [];
try {
  candidateConflicts = JSON.parse(await readFile(candidateConflictPath, 'utf8'));
} catch (_) {
  candidateConflicts = [];
}

function normalize(value) {
  return String(value ?? '').trim().toLocaleLowerCase().replace(/\s+/g, '');
}

function indexNames(field) {
  const index = new Map();
  for (const item of catalog) {
    const names = field(item);
    for (const name of names) {
      const key = normalize(name);
      if (!key) continue;
      const ids = index.get(key) ?? [];
      ids.push(item.id);
      index.set(key, ids);
    }
  }
  return index;
}

const primaryIndex = indexNames((item) => [item.nameZh]);
const aliasIndex = indexNames((item) => item.aliasesZh ?? []);
const englishIndex = indexNames((item) => [item.nameEn]);
const conflicts = (index) => [...index.entries()]
  .map(([name, ids]) => ({ name, ids: [...new Set(ids)] }))
  .filter((item) => item.ids.length > 1);
const aliasPrimaryConflicts = [...aliasIndex.entries()].filter(([name, ids]) => {
  const primaryIds = new Set(primaryIndex.get(name) ?? []);
  return [...primaryIds].some((id) => !ids.includes(id));
});
const variantTokens = [
  '单臂', '双臂', '单腿', '双腿', '宽握', '窄握', '反手', '正手', '对握', '上斜', '下斜',
  '平板', '跪姿', '站姿', '坐姿', '俯身', '辅助', '负重', '暂停', '爆发'
];
const possibleVariantAlias = [];
for (const item of catalog) {
  for (const alias of item.aliasesZh ?? []) {
    const token = variantTokens.find((candidate) => alias.includes(candidate) && !item.nameZh.includes(candidate));
    if (token !== undefined) possibleVariantAlias.push({ id: item.id, alias, token });
  }
}

const counts = { approved: 0, reviewed: 0, auto: 0, raw: 0 };
for (const item of catalog) counts[item.localizationStatus] += 1;
const candidateValues = Object.values(generated);
const high = candidateValues.filter((item) => item.confidence >= 0.92).length;
const medium = candidateValues.filter((item) => item.confidence >= 0.75 && item.confidence < 0.92).length;
const low = candidateValues.filter((item) => item.confidence < 0.75).length;
const qualityCounts = { auto_reviewed: 0, needs_review: 0, needs_manual: 0 };
for (const item of candidateValues) if (qualityCounts[item.qualityGrade] !== undefined) qualityCounts[item.qualityGrade] += 1;
const unknownTokens = candidateValues.filter((item) => (item.unknownTokens ?? []).length > 0);
const candidateFailures = candidateValues.filter((item) => !item.candidate).length;
const variantLost = candidateValues.filter((item) => (item.issues ?? []).includes('variant_lost')).length;
const libraryVisible = catalog.filter((item) => item.libraryVisible === true).length;
const recommended = catalog.filter((item) => item.recommended === true).length;
const recommendedForBeginner = catalog.filter((item) => item.recommendedForBeginner === true).length;

console.log(`总动作数：${catalog.length}`);
console.log(`正式中文动作数：${Object.keys(localization).length}`);
console.log(`成功生成中文候选：${candidateValues.length - candidateFailures}`);
console.log(`候选失败：${candidateFailures}`);
console.log(`approved：${counts.approved}`);
console.log(`reviewed：${counts.reviewed}`);
console.log(`auto：${counts.auto}`);
console.log(`raw：${counts.raw}`);
console.log(`候选高置信度：${high}`);
console.log(`候选中置信度：${medium}`);
console.log(`候选低置信度：${low}`);
console.log(`auto_reviewed：${qualityCounts.auto_reviewed}`);
console.log(`needs_review：${qualityCounts.needs_review}`);
console.log(`needs_manual：${qualityCounts.needs_manual}`);
console.log(`primary-primary 冲突：${conflicts(primaryIndex).length}`);
console.log(`alias-primary 冲突：${aliasPrimaryConflicts.length}`);
console.log(`alias-alias 冲突：${conflicts(aliasIndex).length}`);
console.log(`英文原名冲突：${conflicts(englishIndex).length}`);
console.log(`疑似 variant alias：${possibleVariantAlias.length}`);
console.log(`unknown tokens：${unknownTokens.length}`);
console.log(`candidate 冲突：${candidateConflicts.length}`);
console.log(`variant-lost：${variantLost}`);
console.log(`libraryVisible：${libraryVisible}`);
console.log(`recommended：${recommended}`);
console.log(`recommendedForBeginner：${recommendedForBeginner}`);
