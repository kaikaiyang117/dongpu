export class UserPlanExercise {
  exerciseId: string;
  orderIndex: number;
  sets: number;
  repMin: number;
  repMax: number;
  restSeconds: number;

  constructor(exerciseId: string, orderIndex: number, sets: number, repMin: number, repMax: number,
    restSeconds: number) {
    this.exerciseId = exerciseId;
    this.orderIndex = orderIndex;
    this.sets = sets;
    this.repMin = repMin;
    this.repMax = repMax;
    this.restSeconds = restSeconds;
  }
}

export class UserWorkoutPlan {
  id: number;
  name: string;
  status: string;
  exercises: UserPlanExercise[];

  constructor(id: number, name: string, status: string, exercises: UserPlanExercise[] = []) {
    this.id = id;
    this.name = name;
    this.status = status;
    this.exercises = exercises;
  }
}
