import { util } from '@kit.ArkTS';
import { resourceManager } from '@kit.LocalizationKit';
import { ExerciseResolutionResult, ExerciseResolver } from '../domain/exercise/ExerciseResolver';
import { BodyPart, Exercise, ExerciseRecord } from '../model/Exercise';

export const BODY_PARTS: BodyPart[] = [
  new BodyPart('chest', '胸部'),
  new BodyPart('back', '背部'),
  new BodyPart('shoulders', '肩部'),
  new BodyPart('arms', '手臂'),
  new BodyPart('legs', '腿部'),
  new BodyPart('core', '核心')
];

let cachedExercises: Exercise[] | undefined;

export function loadAllExercises(manager: resourceManager.ResourceManager): Exercise[] {
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

export function loadExercises(manager: resourceManager.ResourceManager): Exercise[] {
  return loadAllExercises(manager);
}

export function getLibraryExercises(exercises: Exercise[]): Exercise[] {
  return exercises.filter(isUserVisibleExercise);
}

export function getApprovedExercises(exercises: Exercise[]): Exercise[] {
  return exercises.filter(isUserVisibleExercise);
}

export function getBeginnerRecommendedExercises(exercises: Exercise[]): Exercise[] {
  return exercises.filter((exercise: Exercise) => isUserVisibleExercise(exercise) &&
    exercise.localizationStatus === 'approved' && exercise.gymEligible && exercise.recommendedForBeginner);
}

export function getGymEligibleApprovedExercises(exercises: Exercise[]): Exercise[] {
  return exercises.filter((exercise: Exercise) => isUserVisibleExercise(exercise) && exercise.gymEligible);
}

export function isUserVisibleExercise(exercise: Exercise): boolean {
  const localizationReady: boolean = exercise.localizationStatus === 'reviewed' ||
    exercise.localizationStatus === 'approved';
  return exercise.contentReviewStatus === 'approved' && localizationReady && exercise.libraryVisible;
}

export function exerciseMatchesPart(exercise: Exercise, userPartId: string): boolean {
  if (userPartId === 'arms') {
    return exercise.partId === 'upper arms' || exercise.partId === 'lower arms';
  }
  if (userPartId === 'legs') {
    return exercise.partId === 'upper legs' || exercise.partId === 'lower legs';
  }
  if (userPartId === 'core') {
    return exercise.partId === 'waist';
  }
  return exercise.partId === userPartId;
}

export function userPartId(exercise: Exercise): string {
  if (exercise.partId === 'upper arms' || exercise.partId === 'lower arms') {
    return 'arms';
  }
  if (exercise.partId === 'upper legs' || exercise.partId === 'lower legs') {
    return 'legs';
  }
  if (exercise.partId === 'waist') {
    return 'core';
  }
  return exercise.partId;
}

export function findExercise(exercises: Exercise[], id: string): Exercise {
  const result: Exercise | undefined = exercises.find((exercise: Exercise) => exercise.id === id);
  if (result === undefined) {
    throw new Error(`Unknown exercise id: ${id}`);
  }
  return result;
}

export function findExerciseExact(exercises: Exercise[], id: string): Exercise | undefined {
  return exercises.find((exercise: Exercise) => exercise.id === id);
}

export function searchLibraryExercises(exercises: Exercise[], keyword: string): Exercise[] {
  const resolver: ExerciseResolver = new ExerciseResolver(getLibraryExercises(exercises));
  return resolver.search(keyword);
}

export function resolveExerciseName(exercises: Exercise[], text: string): Exercise | undefined {
  return new ExerciseResolver(exercises).resolveUniqueByName(text);
}

export function resolveExerciseNameResult(exercises: Exercise[], text: string): ExerciseResolutionResult {
  return new ExerciseResolver(exercises).resolveByName(text);
}
