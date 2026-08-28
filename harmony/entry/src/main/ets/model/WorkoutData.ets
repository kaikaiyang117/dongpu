export class PlanItem {
  exerciseId: string;
  sets: number;
  reps: number;

  constructor(exerciseId: string, sets: number = 3, reps: number = 10) {
    this.exerciseId = exerciseId;
    this.sets = sets;
    this.reps = reps;
  }
}
