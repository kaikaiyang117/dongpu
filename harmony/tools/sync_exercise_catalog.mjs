import { cp, mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, join, parse } from 'node:path';
import { fileURLToPath } from 'node:url';

const toolDir = dirname(fileURLToPath(import.meta.url));
const harmonyDir = dirname(toolDir);
const projectDir = dirname(harmonyDir);
const datasetDir = join(projectDir, 'assets/vendor/exercises-dataset');
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

const preferredNames = {
  '0017': '辅助引体', '0175': '跪姿绳索卷腹', '0179': '绳索低位夹胸', '0195': '牧师椅绳索弯举',
  '0200': '绳索下压', '0215': '绳索反向飞鸟', '0577': '坐姿推胸', '0584': '器械侧平举',
  '0585': '腿屈伸', '0599': '坐姿腿弯举', '0603': '器械推肩', '0818': '高位下拉',
  '0868': '绳索弯举', '0874': '站姿绳索卷腹', '1299': '上斜推胸', '1350': '坐姿划船',
  '1452': '器械卷腹', '2287': '腿举'
};

const source = JSON.parse(await readFile(join(datasetDir, 'data/exercises.json'), 'utf8'));
await mkdir(imageDir, { recursive: true });

const catalog = [];
for (const item of source) {
  const imageName = parse(item.image).base;
  const motionName = `${parse(item.gif_url).name}.mp4`;
  await cp(join(datasetDir, item.image), join(imageDir, imageName));
  const steps = item.instruction_steps?.zh?.filter(Boolean) ?? [];
  catalog.push({
    id: item.id,
    name: preferredNames[item.id] ?? item.name,
    partId: item.body_part,
    equipment: equipment[item.equipment] ?? item.equipment,
    target: targets[item.target] ?? item.target,
    steps: steps.length >= 2 ? steps : [item.instructions?.zh ?? '请查看动作示范。', '使用可控重量缓慢完成动作。'],
    caution: cautions[item.body_part] ?? '从轻重量开始，在可控范围内完成动作。',
    imagePath: `exercise_images/${imageName}`,
    motionPath: `exercise_videos/${motionName}`,
    recommended: beginnerIds.has(item.id)
  });
}

await writeFile(join(rawfileDir, 'exercise_catalog.json'), `${JSON.stringify(catalog)}\n`);
console.log(`Synced ${catalog.length} exercises and ${catalog.length} posters.`);
