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
const categories = ['equipment', 'position', 'laterality', 'angle', 'grip', 'modifier', 'movement'];
const stopWords = new Set(['a', 'an', 'and', 'at', 'by', 'for', 'from', 'in', 'of', 'on', 'the', 'to', 'using', 'with', 'attachment', 'attachments', 'handle', 'handles', 'machine', 'version', 'style']);

function normalizeName(value) {
  return String(value ?? '').toLocaleLowerCase().replace(/[-_/]+/g, ' ').replace(/[^a-z0-9 ]+/g, ' ').replace(/\s+/g, ' ').trim();
}

function normalizeCandidate(value) {
  return String(value ?? '').trim().replace(/\s+/g, '');
}

function escaped(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function entriesFor(category) {
  return Object.entries(terms[category] ?? {})
    .map(([phrase, translation]) => ({ phrase: normalizeName(phrase), translation }))
    .sort((left, right) => right.phrase.length - left.phrase.length);
}

const entries = Object.fromEntries(categories.map((category) => [category, entriesFor(category)]));

function consumeCategory(working, category) {
  const matches = [];
  let remaining = working;
  for (const entry of entries[category]) {
    const pattern = new RegExp(`(?:^|\\s)${escaped(entry.phrase)}(?=\\s|$)`, 'g');
    if (!pattern.test(remaining)) continue;
    pattern.lastIndex = 0;
    matches.push(entry);
    remaining = remaining.replace(pattern, ' ');
  }
  return { remaining: remaining.replace(/\s+/g, ' ').trim(), matches };
}

function includesAny(value, phrases) {
  return phrases.some((phrase) => value.includes(phrase));
}

function inferVariantTags(nameEn) {
  const name = normalizeName(nameEn);
  const tags = [];
  const add = (tag, phrases) => {
    if (includesAny(name, phrases) && !tags.includes(tag)) tags.push(tag);
  };
  add('single_arm', ['single arm', 'one arm']);
  add('double_arm', ['two arm', 'both arms']);
  add('single_leg', ['single leg', 'one leg']);
  add('double_leg', ['two legs', 'both legs']);
  add('wide_grip', ['wide grip']);
  add('narrow_grip', ['narrow grip', 'close grip']);
  add('underhand_grip', ['underhand', 'supinated']);
  add('overhand_grip', ['overhand', 'pronated']);
  add('neutral_grip', ['neutral grip', 'parallel grip']);
  add('incline', ['incline']);
  add('decline', ['decline']);
  add('flat', ['flat bench', 'flat']);
  add('standing', ['standing']);
  add('seated', ['seated']);
  add('kneeling', ['kneeling']);
  add('bent_over', ['bent over']);
  add('assisted', ['assisted']);
  add('weighted', ['weighted']);
  add('paused', ['paused', 'pause']);
  add('explosive', ['explosive', 'plyo']);
  return tags;
}

function hasVariantSemantic(candidate, tag) {
  const semantics = {
    single_arm: ['单臂'], double_arm: ['双臂'], single_leg: ['单腿'], double_leg: ['双腿'],
    wide_grip: ['宽握'], narrow_grip: ['窄握'], underhand_grip: ['反手'], overhand_grip: ['正手'],
    neutral_grip: ['对握'], incline: ['上斜'], decline: ['下斜'], flat: ['平板'], standing: ['站姿'],
    seated: ['坐姿'], kneeling: ['跪姿'], bent_over: ['俯身'], assisted: ['辅助'], weighted: ['负重'],
    paused: ['暂停'], explosive: ['爆发']
  };
  return (semantics[tag] ?? []).some((semantic) => String(candidate).includes(semantic));
}

function inferMovement(nameEn, movementMatches, bodyPart) {
  const name = normalizeName(nameEn);
  const movement = movementMatches.map((match) => match.phrase).join(' + ');
  const text = `${name} ${movement}`;
  let movementPattern = 'other';
  let replacementGroup = 'other';
  let mechanic = 'unknown';
  let force = 'unknown';
  if (includesAny(text, ['stretch', 'mobility', 'flexibility', 'pose'])) {
    movementPattern = 'mobility'; replacementGroup = 'mobility'; mechanic = 'mobility'; force = 'mixed';
  } else if (includesAny(text, ['run', 'bike', 'cycle', 'elliptical', 'sprint', 'jump', 'burpee', 'ergometer'])) {
    movementPattern = 'cardio'; replacementGroup = 'cardio'; mechanic = 'cardio'; force = 'mixed';
  } else if (includesAny(text, ['crunch', 'sit up', 'leg raise', 'knee raise', 'plank', 'dead bug', 'ab roller', 'rollerout'])) {
    movementPattern = includesAny(text, ['twist', 'rotation', 'pallof']) ? 'core_rotation' : 'core_flexion';
    if (includesAny(text, ['plank', 'dead bug', 'rollerout', 'fallout'])) movementPattern = 'core_anti_extension';
    if (includesAny(text, ['pallof'])) movementPattern = 'core_anti_rotation';
    replacementGroup = movementPattern === 'core_anti_extension' ? 'core_anti_extension' : movementPattern === 'core_rotation' || movementPattern === 'core_anti_rotation' ? 'core_rotation' : 'core_flexion';
    mechanic = 'compound'; force = 'mixed';
  } else if (includesAny(text, ['squat', 'leg press', 'leg extension'])) {
    movementPattern = 'squat'; replacementGroup = includesAny(text, ['leg press']) ? 'leg_press' : includesAny(text, ['leg extension']) ? 'quad_extension' : 'squat';
    mechanic = 'compound'; force = 'push';
  } else if (includesAny(text, ['lunge', 'step up', 'step-up', 'split squat'])) {
    movementPattern = 'lunge'; replacementGroup = 'lunge'; mechanic = 'compound'; force = 'push';
  } else if (includesAny(text, ['deadlift', 'hip thrust', 'glute bridge', 'good morning', 'pull through', 'hyperextension'])) {
    movementPattern = 'hinge'; replacementGroup = 'hinge'; mechanic = 'compound'; force = 'pull';
  } else if (includesAny(text, ['lat pulldown', 'pulldown', 'pull up', 'pull-up', 'chin up', 'chin-up'])) {
    movementPattern = 'vertical_pull'; replacementGroup = 'vertical_back_pull'; mechanic = 'compound'; force = 'pull';
  } else if (includesAny(text, ['row'])) {
    movementPattern = 'horizontal_pull'; replacementGroup = 'horizontal_back_pull'; mechanic = 'compound'; force = 'pull';
  } else if (includesAny(text, ['shoulder press', 'military press', 'overhead press', 'push press'])) {
    movementPattern = 'vertical_push'; replacementGroup = 'vertical_shoulder_press'; mechanic = 'compound'; force = 'push';
  } else if (includesAny(text, ['bench press', 'chest press', 'push up', 'push-up', 'dip', 'fly', 'crossover'])) {
    movementPattern = 'horizontal_push'; replacementGroup = includesAny(text, ['fly', 'crossover']) ? 'chest_fly' : 'horizontal_chest_press';
    mechanic = includesAny(text, ['fly', 'crossover']) ? 'isolation' : 'compound'; force = 'push';
  } else if (includesAny(text, ['curl'])) {
    replacementGroup = includesAny(text, ['triceps']) ? 'triceps_extension' : 'biceps_curl'; mechanic = 'isolation'; force = 'pull';
  } else if (includesAny(text, ['raise'])) {
    replacementGroup = includesAny(text, ['rear delt']) ? 'rear_delt_fly' : 'shoulder_raise'; mechanic = 'isolation'; force = 'push';
  } else if (includesAny(text, ['extension', 'pushdown', 'kickback'])) {
    replacementGroup = 'triceps_extension'; mechanic = 'isolation'; force = 'push';
  }
  if (movementPattern === 'other' && bodyPart === 'cardio') {
    movementPattern = 'cardio'; replacementGroup = 'cardio'; mechanic = 'cardio'; force = 'mixed';
  }
  return { mechanic, force, movementPattern, replacementGroup };
}

function parseExerciseName(item) {
  let remaining = normalizeName(item.name);
  const parsedMatches = {};
  for (const category of categories) {
    const result = consumeCategory(remaining, category);
    remaining = result.remaining;
    parsedMatches[category] = result.matches;
  }
  const unknownTokens = remaining.split(' ').filter((token) => token.length > 0 && !stopWords.has(token));
  const movementMatches = parsedMatches.movement;
  const parsed = {};
  for (const category of categories) {
    if (parsedMatches[category][0] !== undefined) {
      parsed[category] = parsedMatches[category].length === 1 ? parsedMatches[category][0].phrase : parsedMatches[category].map((entry) => entry.phrase).join(' + ');
    }
  }
  const variantTags = inferVariantTags(item.name);
  if (movementMatches.length === 0) {
    return { candidate: '', confidence: 0.1, parsed, unknownTokens, variantTags, metadataCandidate: inferMovement(item.name, [], item.body_part), issues: ['movement_unknown'], reason: '未识别到可靠的主体动作，保留为空供审核' };
  }
  const prefixCategories = ['equipment', 'angle', 'grip', 'laterality', 'position', 'modifier'];
  const prefix = prefixCategories.flatMap((category) => parsedMatches[category].map((match) => match.translation)).filter((value, index, values) => values.indexOf(value) === index).join('');
  const candidate = `${prefix}${movementMatches.map((match) => match.translation).join('')}`;
  const structureCount = prefixCategories.reduce((count, category) => count + parsedMatches[category].length, 0);
  let confidence = 0.65;
  if (unknownTokens.length === 0) {
    if (movementMatches.length > 1) confidence = structureCount > 0 ? 0.98 : 0.9;
    else if (structureCount >= 2) confidence = 0.96;
    else if (structureCount === 1) confidence = 0.9;
  } else if (structureCount > 0) confidence = 0.78;
  else if (movementMatches.length > 1) confidence = 0.72;
  const issues = [];
  if (unknownTokens.length > 0) issues.push('unknown_token');
  const lostVariants = variantTags.filter((tag) => !hasVariantSemantic(candidate, tag));
  if (lostVariants.length > 0) { confidence = Math.min(confidence, 0.69); issues.push('variant_lost'); }
  const metadataCandidate = inferMovement(item.name, movementMatches, item.body_part);
  if (metadataCandidate.movementPattern === 'other' || metadataCandidate.replacementGroup === 'other') issues.push('metadata_incomplete');
  return { candidate, confidence, parsed, unknownTokens, variantTags, metadataCandidate, issues, reason: unknownTokens.length === 0 ? `已解析${structureCount > 0 ? '器械/姿势/动作修饰与' : ''}主体动作` : `主体动作明确，但有未识别词：${unknownTokens.join('、')}` };
}

const candidates = {};
for (const item of source) {
  const result = parseExerciseName(item);
  const normalized = normalizeName(item.name);
  const difficulty = normalized.includes('advanced') ? 'advanced' : normalized.includes('intermediate') ? 'intermediate' : 'unknown';
  candidates[item.id] = {
    id: item.id, nameEn: item.name, candidate: result.candidate, confidence: result.confidence,
    translationConfidence: result.confidence, translationMethod: 'structured-parser+rules', parsed: result.parsed,
    unknownTokens: result.unknownTokens, issues: result.issues, qualityGrade: 'needs_manual',
    metadataCandidate: { difficulty, ...result.metadataCandidate, variantTags: result.variantTags }, reason: result.reason
  };
}

const candidateIndex = new Map();
for (const item of Object.values(candidates)) {
  const key = normalizeCandidate(item.candidate);
  if (!key) continue;
  const ids = candidateIndex.get(key) ?? [];
  ids.push(item.id);
  candidateIndex.set(key, ids);
}
for (const item of Object.values(candidates)) {
  const key = normalizeCandidate(item.candidate);
  const collision = key.length > 0 && (candidateIndex.get(key) ?? []).length > 1;
  if (collision && !item.issues.includes('candidate_collision')) item.issues.push('candidate_collision');
  const hasManualIssue = item.candidate.length === 0 || item.confidence < 0.75 || item.issues.includes('variant_lost') || item.issues.includes('movement_unknown');
  const canAutoReview = item.confidence >= 0.92 && item.unknownTokens.length === 0 && item.candidate.length > 0 && !collision && !item.issues.includes('variant_lost') && !item.issues.includes('metadata_incomplete');
  item.qualityGrade = canAutoReview ? 'auto_reviewed' : hasManualIssue ? 'needs_manual' : 'needs_review';
}

await mkdir(outputDir, { recursive: true });
await writeFile(join(outputDir, 'exercise_localization_candidates.zh-CN.json'), `${JSON.stringify(candidates, null, 2)}\n`);
console.log(`Generated ${Object.keys(candidates).length} translation and metadata candidates without changing formal localization.`);
