export class PlanItem {
  exerciseId: string;
  sets: number;
  repMin: number;
  repMax: number;
  restSeconds: number;

  constructor(exerciseId: string, sets: number = 3, repMin: number = 10, repMax: number = 12,
    restSeconds: number = 60) {
    this.exerciseId = exerciseId;
    this.sets = sets;
    this.repMin = repMin;
    this.repMax = repMax;
    this.restSeconds = restSeconds;
  }
}
