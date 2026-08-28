import { util } from '@kit.ArkTS';
import { resourceManager } from '@kit.LocalizationKit';
import { BodyPart, Exercise, ExerciseRecord } from '../model/Exercise';

export const BODY_PARTS: BodyPart[] = [
  new BodyPart('chest', '胸部'),
  new BodyPart('back', '背部'),
  new BodyPart('shoulders', '肩部'),
  new BodyPart('upper arms', '上臂'),
  new BodyPart('lower arms', '前臂'),
  new BodyPart('upper legs', '大腿'),
  new BodyPart('lower legs', '小腿'),
  new BodyPart('waist', '核心'),
  new BodyPart('cardio', '有氧'),
  new BodyPart('neck', '颈部')
];

let cachedExercises: Exercise[] | undefined;

export function loadExercises(manager: resourceManager.ResourceManager): Exercise[] {
  if (cachedExercises !== undefined) {
    return cachedExercises;
  }

  try {
    const bytes: Uint8Array = manager.getRawFileContentSync('exercise_catalog.json');
    const json: string = util.TextDecoder.create('utf-8', { ignoreBOM: true }).decodeToString(bytes);
    const records: ExerciseRecord[] = JSON.parse(json) as ExerciseRecord[];
    cachedExercises = records.map((record: ExerciseRecord) => new Exercise(record));
  } catch (_) {
    cachedExercises = [];
  }
  return cachedExercises;
}

export function findExercise(exercises: Exercise[], id: string): Exercise {
  const result: Exercise | undefined = exercises.find((exercise: Exercise) => exercise.id === id);
  return result ?? exercises[0];
}
