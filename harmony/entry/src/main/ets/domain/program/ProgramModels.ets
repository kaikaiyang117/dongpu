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

  constructor(exerciseId: string, nameSnapshot: string, partName: string, equipmentName: string, imagePath: string,
    sets: number = 3, repMin: number = 8, repMax: number = 12, restSeconds: number = 60) {
    this.exerciseId = exerciseId;
    this.nameSnapshot = nameSnapshot;
    this.partName = partName;
    this.equipmentName = equipmentName;
    this.imagePath = imagePath;
    this.sets = sets;
    this.repMin = repMin;
    this.repMax = repMax;
    this.restSeconds = restSeconds;
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
  new ProgramExercise('0739', '腿举', '腿部', '腿举机', 'exercise_images/0739-10Z2DXU.jpg'),
  new ProgramExercise('0576', '坐姿推胸', '胸部', '推胸机', 'exercise_images/0576-DOoWcnA.jpg'),
  new ProgramExercise('0673', '高位下拉', '背部', '高位下拉机', 'exercise_images/0673-ecpY0rH.jpg'),
  new ProgramExercise('0586', '腿弯举', '腿部', '腿弯举机', 'exercise_images/0586-17lJ1kr.jpg', 3, 10, 12),
  new ProgramExercise('0588', '坐姿划船', '背部', '划船机', 'exercise_images/0588-IGjKj1v.jpg')
]);

const WORKOUT_B: ProgramWorkout = new ProgramWorkout('B', '全身训练', 38, [
  new ProgramExercise('1425', '单腿腿举', '腿部', '腿举机', 'exercise_images/1425-WWD6FzI.jpg'),
  new ProgramExercise('1479', '上斜推胸', '胸部', '推胸机', 'exercise_images/1479-o17Jfkt.jpg'),
  new ProgramExercise('2330', '高位下拉', '背部', '高位下拉机', 'exercise_images/2330-LEprlgG.jpg'),
  new ProgramExercise('0582', '跪姿腿弯举', '腿部', '腿弯举机', 'exercise_images/0582-nnmCTLN.jpg', 3, 10, 12),
  new ProgramExercise('0571', '坐姿划船', '背部', '划船机', 'exercise_images/0571-w2oRpuH.jpg')
]);

export const BEGINNER_PROGRAM: BeginnerProgram = new BeginnerProgram('beginner-ab', '新手全身 A/B', [WORKOUT_A, WORKOUT_B]);

export function recommendedWorkout(code: string): ProgramWorkout {
  return code === 'B' ? WORKOUT_B : WORKOUT_A;
}
