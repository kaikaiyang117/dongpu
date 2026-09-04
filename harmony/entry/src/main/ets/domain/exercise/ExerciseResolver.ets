import { Exercise } from '../../model/Exercise';

function normalize(value: string): string {
  return value.trim().toLocaleLowerCase().replace(/\s+/g, '');
}

export type ExerciseResolutionStatus = 'resolved' | 'ambiguous' | 'not_found';

export class ExerciseResolutionResult {
  status: ExerciseResolutionStatus;
  exercise?: Exercise;
  candidates: Exercise[];

  constructor(status: ExerciseResolutionStatus, candidates: Exercise[] = []) {
    this.status = status;
    this.candidates = candidates;
    if (candidates.length === 1) {
      this.exercise = candidates[0];
    }
  }
}

export class ExerciseResolver {
  private exercises: Exercise[];
  private idIndex: Map<string, Exercise>;
  private exactNameIndex: Map<string, Exercise[]>;

  constructor(exercises: Exercise[] = []) {
    this.exercises = exercises;
    this.idIndex = new Map<string, Exercise>();
    this.exactNameIndex = new Map<string, Exercise[]>();
    exercises.forEach((exercise: Exercise) => {
      this.idIndex.set(exercise.id, exercise);
      const names: string[] = [exercise.nameZh, exercise.nameEn, ...exercise.aliasesZh];
      names.forEach((name: string) => {
        const key: string = normalize(name);
        if (key.length === 0) {
          return;
        }
        const list: Exercise[] = this.exactNameIndex.get(key) ?? [];
        if (!list.some((item: Exercise) => item.id === exercise.id)) {
          list.push(exercise);
        }
        this.exactNameIndex.set(key, list);
      });
    });
  }

  resolveById(id: string): Exercise | undefined {
    return this.idIndex.get(id);
  }

  resolveByName(text: string): ExerciseResolutionResult {
    const keyword: string = normalize(text);
    if (keyword.length === 0) {
      return new ExerciseResolutionResult('not_found');
    }
    const candidates: Exercise[] = this.exactNameIndex.get(keyword) ?? [];
    if (candidates.length === 0) {
      return new ExerciseResolutionResult('not_found');
    }
    if (candidates.length > 1) {
      return new ExerciseResolutionResult('ambiguous', candidates);
    }
    return new ExerciseResolutionResult('resolved', candidates);
  }

  resolveUniqueByName(text: string): Exercise | undefined {
    const result: ExerciseResolutionResult = this.resolveByName(text);
    return result.status === 'resolved' ? result.exercise : undefined;
  }

  search(keyword: string): Exercise[] {
    const normalized: string = normalize(keyword);
    if (normalized.length === 0) {
      return this.exercises;
    }
    return this.exercises.filter((exercise: Exercise) => {
      const fields: string[] = [exercise.nameZh, exercise.nameEn, ...exercise.aliasesZh,
        exercise.equipment, exercise.target];
      return fields.some((value: string) => normalize(value).includes(normalized));
    });
  }
}
