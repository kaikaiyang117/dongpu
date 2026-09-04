import { Exercise } from '../../model/Exercise';

function normalize(value: string): string {
  return value.trim().toLocaleLowerCase().replace(/\s+/g, '');
}

export class ExerciseResolver {
  private exercises: Exercise[];

  constructor(exercises: Exercise[] = []) {
    this.exercises = exercises;
  }

  resolveById(id: string): Exercise | undefined {
    return this.exercises.find((exercise: Exercise) => exercise.id === id);
  }

  resolveByName(text: string): Exercise | undefined {
    const keyword: string = normalize(text);
    return this.exercises.find((exercise: Exercise) => {
      return [exercise.displayName, exercise.nameZh, exercise.nameEn, ...exercise.aliasesZh]
        .some((value: string) => normalize(value) === keyword);
    });
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
