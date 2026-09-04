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

const rules = [
  [/^cable kneeling crunch/i, () => '跪姿绳索卷腹'],
  [/^cable standing crunch/i, () => '站姿绳索卷腹'],
  [/^cable .*pushdown/i, () => '绳索下压'],
  [/^cable .*fly/i, () => '绳索夹胸'],
  [/^cable .*curl/i, () => '绳索弯举'],
  [/^cable .*rear lateral raise/i, () => '绳索反向飞鸟'],
  [/^lever incline chest press/i, () => '上斜器械推胸'],
  [/^lever chest press/i, () => '器械推胸'],
  [/^lever lateral raise/i, () => '器械侧平举'],
  [/^lever leg extension/i, () => '腿屈伸'],
  [/^lever seated leg curl/i, () => '坐姿腿弯举'],
  [/^lever seated crunch/i, () => '器械卷腹'],
  [/^lever seated row/i, () => '坐姿划船'],
  [/^lever shoulder press/i, () => '器械推肩'],
  [/^lever .*leg press/i, () => '腿举'],
  [/^assisted pull-up/i, () => '辅助引体'],
  [/lat pulldown/i, () => '高位下拉'],
  [/bench press/i, () => '卧推'],
  [/chest press/i, () => '推胸'],
  [/deadlift/i, () => '硬拉'],
  [/squat/i, () => '深蹲'],
  [/lunge/i, () => '弓步'],
  [/crunch/i, () => '卷腹'],
  [/plank/i, () => '平板支撑'],
  [/row/i, () => '划船'],
  [/curl/i, () => '弯举'],
  [/pushdown/i, () => '下压'],
  [/lateral raise/i, () => '侧平举']
];

function candidateFor(item) {
  const rule = rules.find(([pattern]) => pattern.test(item.name));
  if (rule !== undefined) {
    return { candidate: rule[1](), confidence: 0.82, reason: '基于动作结构与器械术语的确定性候选规则' };
  }
  const matchedTerm = Object.keys(terms).find((term) => item.name.toLocaleLowerCase().includes(term));
  if (matchedTerm !== undefined) {
    return { candidate: terms[matchedTerm], confidence: 0.55, reason: `命中术语参考：${matchedTerm}` };
  }
  return { candidate: '', confidence: 0.1, reason: '缺少足够结构信息，保留为空供审核' };
}

const candidates = {};
for (const item of source) {
  const result = candidateFor(item);
  candidates[item.id] = {
    nameEn: item.name,
    candidate: result.candidate,
    aliases: [],
    confidence: result.confidence,
    reason: result.reason,
    status: 'auto'
  };
}

await mkdir(outputDir, { recursive: true });
await writeFile(join(outputDir, 'exercise_localization_candidates.zh-CN.json'), `${JSON.stringify(candidates, null, 2)}\n`);
console.log(`Generated ${Object.keys(candidates).length} translation candidates without changing formal localization.`);
