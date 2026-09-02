export enum WorkoutStatus {
  Active = 'active',
  Completed = 'completed',
  Abandoned = 'abandoned'
}

export enum WorkoutPhase {
  Exercise = 'exercise',
  Rest = 'rest',
  ExerciseCompleted = 'exercise-completed',
  Complete = 'complete'
}

export class SetRecord {
  id: number;
  exerciseRecordId: number;
  setNumber: number;
  weight: number;
  reps: number;
  completedAt: number;

  constructor(id: number, exerciseRecordId: number, setNumber: number, weight: number, reps: number,
    completedAt: number) {
    this.id = id;
    this.exerciseRecordId = exerciseRecordId;
    this.setNumber = setNumber;
    this.weight = weight;
    this.reps = reps;
    this.completedAt = completedAt;
  }
}

export class WorkoutExerciseRecord {
  id: number;
  sessionId: number;
  originalExerciseId: string;
  actualExerciseId: string;
  exerciseNameSnapshot: string;
  partNameSnapshot: string;
  equipmentNameSnapshot: string;
  imagePathSnapshot: string;
  orderIndex: number;
  targetSets: number;
  repMin: number;
  repMax: number;
  restSeconds: number;
  completedSets: number;
  setRecords: SetRecord[];
  suggestedWeight: number;
  suggestedReps: number;

  constructor(id: number, sessionId: number, originalExerciseId: string, actualExerciseId: string,
    exerciseNameSnapshot: string, partNameSnapshot: string, equipmentNameSnapshot: string,
    imagePathSnapshot: string, orderIndex: number, targetSets: number, repMin: number, repMax: number,
    restSeconds: number, completedSets: number = 0, setRecords: SetRecord[] = [], suggestedWeight: number = 0,
    suggestedReps: number = 10) {
    this.id = id;
    this.sessionId = sessionId;
    this.originalExerciseId = originalExerciseId;
    this.actualExerciseId = actualExerciseId;
    this.exerciseNameSnapshot = exerciseNameSnapshot;
    this.partNameSnapshot = partNameSnapshot;
    this.equipmentNameSnapshot = equipmentNameSnapshot;
    this.imagePathSnapshot = imagePathSnapshot;
    this.orderIndex = orderIndex;
    this.targetSets = targetSets;
    this.repMin = repMin;
    this.repMax = repMax;
    this.restSeconds = restSeconds;
    this.completedSets = completedSets;
    this.setRecords = setRecords;
    this.suggestedWeight = suggestedWeight;
    this.suggestedReps = suggestedReps;
  }
}

export class WorkoutSession {
  id: number;
  workoutCode: string;
  workoutNameSnapshot: string;
  sourceType: string;
  status: WorkoutStatus;
  phase: WorkoutPhase;
  currentExerciseIndex: number;
  startedAt: number;
  completedAt: number;
  restEndAt: number;
  programId: string;
  programWorkoutId: string;
  programVersion: string;
  goalId: number;
  exercises: WorkoutExerciseRecord[];

  constructor(id: number, workoutCode: string, workoutNameSnapshot: string, sourceType: string,
    status: WorkoutStatus, phase: WorkoutPhase, currentExerciseIndex: number, startedAt: number,
    completedAt: number = 0, restEndAt: number = 0, exercises: WorkoutExerciseRecord[] = [],
    programId: string = '', programWorkoutId: string = '', programVersion: string = '', goalId: number = 0) {
    this.id = id;
    this.workoutCode = workoutCode;
    this.workoutNameSnapshot = workoutNameSnapshot;
    this.sourceType = sourceType;
    this.status = status;
    this.phase = phase;
    this.currentExerciseIndex = currentExerciseIndex;
    this.startedAt = startedAt;
    this.completedAt = completedAt;
    this.restEndAt = restEndAt;
    this.programId = programId;
    this.programWorkoutId = programWorkoutId;
    this.programVersion = programVersion;
    this.goalId = goalId;
    this.exercises = exercises;
  }
}

export class UserProgramState {
  nextWorkoutCode: string;
  weeklyCompleted: number;

  constructor(nextWorkoutCode: string = 'A', weeklyCompleted: number = 0) {
    this.nextWorkoutCode = nextWorkoutCode;
    this.weeklyCompleted = weeklyCompleted;
  }
}

export class ExerciseProgress {
  exerciseName: string;
  previousWeight: number;
  currentWeight: number;
  previousReps: number;
  currentReps: number;

  constructor(exerciseName: string, previousWeight: number, currentWeight: number,
    previousReps: number, currentReps: number) {
    this.exerciseName = exerciseName;
    this.previousWeight = previousWeight;
    this.currentWeight = currentWeight;
    this.previousReps = previousReps;
    this.currentReps = currentReps;
  }

  get hasWeightProgress(): boolean {
    return this.currentWeight > this.previousWeight;
  }

  get hasRepsProgress(): boolean {
    return this.currentReps > this.previousReps;
  }
}
