import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const toolDir = dirname(fileURLToPath(import.meta.url));
const harmonyDir = resolve(toolDir, '..');
const projectDir = resolve(harmonyDir, '..');
const datasetDir = join(projectDir, 'assets/vendor/exercises-dataset');
const source = JSON.parse(await readFile(join(datasetDir, 'data/exercises.json'), 'utf8'));
const terms = JSON.parse(await readFile(join(harmonyDir, 'data/exercise_terms.zh-CN.json'), 'utf8'));
const outputDir = join(harmonyDir, 'data/generated');

function normalizeName(value) {
  return value.toLocaleLowerCase().replace(/[-_/]+/g, ' ').replace(/[^a-z0-9 ]+/g, ' ')
    .replace(/\s+/g, ' ').trim();
}

function escaped(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function entriesFor(category) {
  return Object.entries(terms[category] ?? {})
    .map(([phrase, translation]) => ({ phrase: normalizeName(phrase), translation }))
    .sort((left, right) => right.phrase.length - left.phrase.length);
}

const categories = ['equipment', 'position', 'laterality', 'angle', 'grip', 'modifier', 'movement'];
const entries = Object.fromEntries(categories.map((category) => [category, entriesFor(category)]));
const stopWords = new Set([
  'a', 'an', 'and', 'at', 'by', 'for', 'from', 'in', 'of', 'on', 'the', 'to', 'using', 'with',
  'attachment', 'attachments', 'handle', 'handles', 'machine', 'version', 'style'
]);

function consumeCategory(working, category) {
  const matches = [];
  let remaining = working;
  for (const entry of entries[category]) {
    const pattern = new RegExp(`(?:^|\\s)${escaped(entry.phrase)}(?=\\s|$)`, 'g');
    if (pattern.test(remaining)) {
      matches.push(entry);
      remaining = remaining.replace(pattern, ' ');
    }
  }
  return { remaining: remaining.replace(/\s+/g, ' ').trim(), matches };
}

function firstMatch(matches) {
  return matches[0];
}

function parseExerciseName(nameEn) {
  let remaining = normalizeName(nameEn);
  const parsedMatches = {};
  for (const category of categories) {
    const result = consumeCategory(remaining, category);
    remaining = result.remaining;
    parsedMatches[category] = result.matches;
  }

  const unknownTokens = remaining.split(' ').filter((token) => token.length > 0 && !stopWords.has(token));
  const movementMatches = parsedMatches.movement;
  const movement = firstMatch(movementMatches);
  const parsed = {};
  for (const category of categories) {
    const match = firstMatch(parsedMatches[category]);
    if (match !== undefined) {
      parsed[category] = parsedMatches[category].length === 1
        ? match.phrase
        : parsedMatches[category].map((item) => item.phrase).join(' + ');
    }
  }

  if (movement === undefined) {
    return {
      candidate: '',
      confidence: 0.1,
      parsed,
      unknownTokens,
      reason: '未识别到可靠的主体动作，保留为空供审核'
    };
  }

  const prefixCategories = ['equipment', 'angle', 'grip', 'laterality', 'position', 'modifier'];
  const prefix = prefixCategories
    .flatMap((category) => parsedMatches[category].map((match) => match.translation))
    .filter((value, index, values) => values.indexOf(value) === index)
    .join('');
  const movementText = movementMatches.map((match) => match.translation).join('');
  const candidate = `${prefix}${movementText}`;
  const structureCount = prefixCategories.reduce((count, category) => count + parsedMatches[category].length, 0);
  let confidence = 0.65;
  if (unknownTokens.length === 0) {
    if (movementMatches.length > 1) confidence = structureCount > 0 ? 0.98 : 0.9;
    else if (structureCount >= 2) confidence = 0.96;
    else if (structureCount === 1) confidence = 0.9;
  } else if (structureCount > 0) {
    confidence = 0.78;
  } else if (movementMatches.length > 1) {
    confidence = 0.72;
  }
  const reason = unknownTokens.length === 0
    ? `已解析${structureCount > 0 ? '器械/姿势/动作修饰与' : ''}主体动作`
    : `主体动作明确，但有未识别词：${unknownTokens.join('、')}`;
  return { candidate, confidence, parsed, unknownTokens, reason };
}

const candidates = {};
for (const item of source) {
  const result = parseExerciseName(item.name);
  candidates[item.id] = {
    id: item.id,
    nameEn: item.name,
    candidate: result.candidate,
    confidence: result.confidence,
    parsed: result.parsed,
    unknownTokens: result.unknownTokens,
    reason: result.reason,
    aliases: [],
    status: 'auto',
    reviewDecision: 'pending',
    reviewedName: '',
    reviewNote: ''
  };
}

await mkdir(outputDir, { recursive: true });
await writeFile(join(outputDir, 'exercise_localization_candidates.zh-CN.json'), `${JSON.stringify(candidates, null, 2)}\n`);
console.log(`Generated ${Object.keys(candidates).length} translation candidates without changing formal localization.`);
