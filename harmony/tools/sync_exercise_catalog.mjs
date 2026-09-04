import { cp, mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, join, parse } from 'node:path';
import { fileURLToPath } from 'node:url';

const toolDir = dirname(fileURLToPath(import.meta.url));
const harmonyDir = dirname(toolDir);
const projectDir = dirname(harmonyDir);
const datasetDir = join(projectDir, 'assets/vendor/exercises-dataset');
const dataDir = join(harmonyDir, 'data');
const rawfileDir = join(harmonyDir, 'entry/src/main/resources/rawfile');
const imageDir = join(rawfileDir, 'exercise_images');

const equipment = {
  assisted: '辅助器械', band: '弹力带', barbell: '杠铃', 'body weight': '自重', 'bosu ball': '波速球',
  cable: '龙门架', dumbbell: '哑铃', 'elliptical machine': '椭圆机', 'ez barbell': '曲杆杠铃', hammer: '训练锤',
  kettlebell: '壶铃', 'leverage machine': '固定器械', 'medicine ball': '药球', 'olympic barbell': '奥林匹克杠铃',
  'resistance band': '阻力带', roller: '泡沫轴', rope: '训练绳', 'skierg machine': '滑雪机',
  'sled machine': '雪橇机', 'smith machine': '史密斯机', 'stability ball': '健身球',
  'stationary bike': '动感单车', 'stepmill machine': '登阶机', tire: '轮胎', 'trap bar': '六角杠铃',
  'upper body ergometer': '上肢功率车', weighted: '负重', 'wheel roller': '健腹轮'
};

const targets = {
  abs: '腹部', abductors: '髋外展肌', adductors: '髋内收肌', biceps: '肱二头肌', calves: '小腿',
  'cardiovascular system': '心肺系统', delts: '三角肌', forearms: '前臂', glutes: '臀部',
  hamstrings: '大腿后侧', lats: '背阔肌', 'levator scapulae': '肩胛提肌', pectorals: '胸肌',
  quads: '大腿前侧', 'serratus anterior': '前锯肌', spine: '脊柱稳定肌', traps: '斜方肌',
  triceps: '肱三头肌', 'upper back': '上背部'
};

const cautions = {
  back: '保持脊柱自然，不要大幅后仰或用惯性拉动重量。',
  cardio: '先从低强度开始，出现头晕、胸闷或异常疼痛时立即停止。',
  chest: '不要耸肩或让腰背过度拱起，避免肩部代偿。',
  'lower arms': '保持手腕稳定，避免使用过大的重量。',
  'lower legs': '脚踝保持稳定，动作缓慢，不要快速弹震。',
  neck: '只使用轻阻力和可控幅度，出现颈部疼痛时立即停止。',
  shoulders: '肩膀保持放松，动作幅度适中，不要借力甩动。',
  'upper arms': '固定上臂，避免摆动身体借力。',
  'upper legs': '膝盖跟随脚尖方向，重量从轻开始，不要锁死膝关节。',
  waist: '保持呼吸，用核心控制动作，不要拉扯颈部或过度弯腰。'
};

const beginnerIds = new Set([
  '0017', '0175', '0179', '0195', '0200', '0215', '0577', '0584', '0585',
  '0599', '0603', '0818', '0868', '0874', '1299', '1350', '1452', '2287'
]);

const source = JSON.parse(await readFile(join(datasetDir, 'data/exercises.json'), 'utf8'));
const localization = JSON.parse(await readFile(join(dataDir, 'exercise_localization.zh-CN.json'), 'utf8'));
const metadataOverrides = JSON.parse(await readFile(join(dataDir, 'exercise_metadata_overrides.json'), 'utf8'));
await mkdir(imageDir, { recursive: true });

const localizationStatuses = new Set(['raw', 'auto', 'reviewed', 'approved']);

function readLocalization(item) {
  const localized = localization[item.id];
  if (localized === undefined) {
    return { nameZh: '', aliasesZh: [], status: 'raw' };
  }
  if (localized.nameZh !== undefined && typeof localized.nameZh !== 'string') {
    throw new Error(`Invalid nameZh for ${item.id}: expected string`);
  }
  if (localized.aliasesZh !== undefined && !Array.isArray(localized.aliasesZh)) {
    throw new Error(`Invalid aliasesZh for ${item.id}: expected array`);
  }
  const nameZh = (localized.nameZh ?? '').trim();
  const aliasesZh = localized.aliasesZh ?? [];
  const normalizedAliases = new Set();
  for (const alias of aliasesZh) {
    if (typeof alias !== 'string' || alias.trim().length === 0) {
      throw new Error(`Invalid empty alias for ${item.id}`);
    }
    const normalizedAlias = alias.trim();
    if (normalizedAlias === nameZh) {
      throw new Error(`Alias duplicates nameZh for ${item.id}: ${normalizedAlias}`);
    }
    if (normalizedAliases.has(normalizedAlias)) {
      throw new Error(`Duplicate alias for ${item.id}: ${normalizedAlias}`);
    }
    normalizedAliases.add(normalizedAlias);
  }
  const status = localized.status ?? 'raw';
  if (!localizationStatuses.has(status)) {
    throw new Error(`Invalid localizationStatus for ${item.id}: ${status}`);
  }
  return { nameZh, aliasesZh: aliasesZh.map((alias) => alias.trim()), status };
}

const catalog = [];
for (const item of source) {
  const localized = readLocalization(item);
  const metadata = metadataOverrides[item.id] ?? {};
  const imageName = parse(item.image).base;
  const motionName = `${parse(item.gif_url).name}.mp4`;
  await cp(join(datasetDir, item.image), join(imageDir, imageName));
  const steps = item.instruction_steps?.zh?.filter(Boolean) ?? [];
  catalog.push({
    id: item.id,
    nameEn: item.name,
    nameZh: localized.nameZh,
    aliasesZh: localized.aliasesZh,
    name: localized.nameZh.length > 0 ? localized.nameZh : item.name,
    partId: item.body_part,
    equipment: equipment[item.equipment] ?? item.equipment,
    target: targets[item.target] ?? item.target,
    steps: steps.length >= 2 ? steps : [item.instructions?.zh ?? '请查看动作示范。', '使用可控重量缓慢完成动作。'],
    caution: cautions[item.body_part] ?? '从轻重量开始，在可控范围内完成动作。',
    equipmentSetup: `调整${equipment[item.equipment] ?? item.equipment}到舒适且稳定的位置，先用轻重量确认动作路径。`,
    imagePath: `exercise_images/${imageName}`,
    motionPath: `exercise_videos/${motionName}`,
    difficulty: metadata.difficulty ?? 'unknown',
    mechanic: metadata.mechanic ?? 'unknown',
    force: metadata.force ?? 'unknown',
    movementPattern: metadata.movementPattern ?? 'other',
    variantTags: metadata.variantTags ?? [],
    replacementGroup: metadata.replacementGroup ?? '',
    recommended: beginnerIds.has(item.id),
    recommendedForBeginner: beginnerIds.has(item.id),
    gymEligible: true,
    localizationStatus: localized.status,
    contentReviewStatus: beginnerIds.has(item.id) ? 'approved' : 'reviewed',
    libraryVisible: true
  });
}

await writeFile(join(rawfileDir, 'exercise_catalog.json'), `${JSON.stringify(catalog)}\n`);
console.log(`Synced ${catalog.length} exercises and ${catalog.length} posters.`);
