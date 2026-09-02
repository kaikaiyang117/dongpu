export class TrainingProgram {
  id: string;
  version: string;
  name: string;
  goalType: string;
  durationWeeks: number;
  minSessions: number;
  maxSessions: number;
  reviewStatus: string;
  isBuiltin: boolean;

  constructor(id: string = '', version: string = '', name: string = '', goalType: string = '',
    durationWeeks: number = 0, minSessions: number = 0, maxSessions: number = 0,
    reviewStatus: string = 'raw', isBuiltin: boolean = false) {
    this.id = id;
    this.version = version;
    this.name = name;
    this.goalType = goalType;
    this.durationWeeks = durationWeeks;
    this.minSessions = minSessions;
    this.maxSessions = maxSessions;
    this.reviewStatus = reviewStatus;
    this.isBuiltin = isBuiltin;
  }
}

export class ProgramWorkoutV2 {
  id: string;
  programId: string;
  code: string;
  name: string;
  focusText: string;
  orderIndex: number;
  optional: boolean;
  estimatedMinutes: number;
  exercises: ProgramWorkoutExerciseV2[];

  constructor(id: string = '', programId: string = '', code: string = '', name: string = '', focusText: string = '',
    orderIndex: number = 0, optional: boolean = false, estimatedMinutes: number = 0,
    exercises: ProgramWorkoutExerciseV2[] = []) {
    this.id = id;
    this.programId = programId;
    this.code = code;
    this.name = name;
    this.focusText = focusText;
    this.orderIndex = orderIndex;
    this.optional = optional;
    this.estimatedMinutes = estimatedMinutes;
    this.exercises = exercises;
  }
}

export class ProgramWorkoutExerciseV2 {
  id: number;
  workoutId: string;
  exerciseId: string;
  orderIndex: number;
  plannedSets: number;
  repMin: number;
  repMax: number;
  restSeconds: number;
  weightIncrementKg: number;

  constructor(id: number = 0, workoutId: string = '', exerciseId: string = '', orderIndex: number = 0,
    plannedSets: number = 0, repMin: number = 0, repMax: number = 0, restSeconds: number = 0,
    weightIncrementKg: number = 2.5) {
    this.id = id;
    this.workoutId = workoutId;
    this.exerciseId = exerciseId;
    this.orderIndex = orderIndex;
    this.plannedSets = plannedSets;
    this.repMin = repMin;
    this.repMax = repMax;
    this.restSeconds = restSeconds;
    this.weightIncrementKg = weightIncrementKg;
  }
}

export class ActiveProgramState {
  id: number;
  goalId: number;
  programId: string;
  programVersion: string;
  startedAt: number;
  currentWeek: number;
  nextRequiredWorkoutIndex: number;

  constructor(id: number = 1, goalId: number = 0, programId: string = '', programVersion: string = '',
    startedAt: number = 0, currentWeek: number = 1, nextRequiredWorkoutIndex: number = 0) {
    this.id = id;
    this.goalId = goalId;
    this.programId = programId;
    this.programVersion = programVersion;
    this.startedAt = startedAt;
    this.currentWeek = currentWeek;
    this.nextRequiredWorkoutIndex = nextRequiredWorkoutIndex;
  }
}
