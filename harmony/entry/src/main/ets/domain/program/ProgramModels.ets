export class ProgramExercise {
  exerciseId: string;
  nameSnapshot: string;
  partName: string;
  equipmentName: string;
  sets: number;
  repMin: number;
  repMax: number;
  restSeconds: number;
  imagePath: string;
  programWorkoutExerciseId: number;
  weightIncrementKg: number;

  constructor(exerciseId: string, nameSnapshot: string, partName: string, equipmentName: string, imagePath: string,
    sets: number = 3, repMin: number = 8, repMax: number = 12, restSeconds: number = 60,
    programWorkoutExerciseId: number = 0, weightIncrementKg: number = 2.5) {
    this.exerciseId = exerciseId;
    this.nameSnapshot = nameSnapshot;
    this.partName = partName;
    this.equipmentName = equipmentName;
    this.imagePath = imagePath;
    this.sets = sets;
    this.repMin = repMin;
    this.repMax = repMax;
    this.restSeconds = restSeconds;
    this.programWorkoutExerciseId = programWorkoutExerciseId;
    this.weightIncrementKg = weightIncrementKg;
  }
}

export class ProgramWorkout {
  code: string;
  name: string;
  estimatedMinutes: number;
  exercises: ProgramExercise[];

  constructor(code: string, name: string, estimatedMinutes: number, exercises: ProgramExercise[]) {
    this.code = code;
    this.name = name;
    this.estimatedMinutes = estimatedMinutes;
    this.exercises = exercises;
  }
}

export class BeginnerProgram {
  id: string;
  name: string;
  workouts: ProgramWorkout[];

  constructor(id: string, name: string, workouts: ProgramWorkout[]) {
    this.id = id;
    this.name = name;
    this.workouts = workouts;
  }
}

const WORKOUT_A: ProgramWorkout = new ProgramWorkout('A', '全身训练', 40, [
  new ProgramExercise('2287', '腿举', '腿部', '固定器械', 'exercise_images/2287-V07qpXy.jpg'),
  new ProgramExercise('0577', '坐姿推胸', '胸部', '固定器械', 'exercise_images/0577-T0yTjgW.jpg'),
  new ProgramExercise('0818', '高位下拉', '背部', '龙门架', 'exercise_images/0818-rkg41Fb.jpg'),
  new ProgramExercise('0599', '坐姿腿弯举', '腿部', '固定器械', 'exercise_images/0599-Zg3XY7P.jpg', 3, 10, 12),
  new ProgramExercise('1350', '坐姿划船', '背部', '固定器械', 'exercise_images/1350-7I6LNUG.jpg')
]);

const WORKOUT_B: ProgramWorkout = new ProgramWorkout('B', '全身训练', 38, [
  new ProgramExercise('1299', '上斜推胸', '胸部', '固定器械', 'exercise_images/1299-jHAnWmT.jpg'),
  new ProgramExercise('0603', '器械推肩', '肩部', '固定器械', 'exercise_images/0603-67n3r98.jpg'),
  new ProgramExercise('0017', '辅助引体', '背部', '固定器械', 'exercise_images/0017-kiJ4Z2K.jpg'),
  new ProgramExercise('0585', '腿屈伸', '腿部', '固定器械', 'exercise_images/0585-my33uHU.jpg', 3, 10, 12),
  new ProgramExercise('1452', '器械卷腹', '核心', '固定器械', 'exercise_images/1452-Wgaz7pm.jpg')
]);

export const BEGINNER_PROGRAM: BeginnerProgram = new BeginnerProgram('beginner-ab', '新手全身 A/B', [WORKOUT_A, WORKOUT_B]);

export function recommendedWorkout(code: string): ProgramWorkout {
  return code === 'B' ? WORKOUT_B : WORKOUT_A;
}
