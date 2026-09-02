export class FitnessGoal {
  id: number;
  goalType: string;
  startWeightKg: number;
  targetWeightKg: number;
  startDate: number;
  targetCalories: number;
  targetProteinG: number;
  targetSteps: number;
  trainingFrequencyMin: number;
  trainingFrequencyMax: number;
  trainingLocation: string;
  dedicatedLegDay: boolean;
  preferMachines: boolean;
  status: string;
  createdAt: number;
  updatedAt: number;

  constructor(id: number = 0, goalType: string = 'fat_loss', startWeightKg: number = 0,
    targetWeightKg: number = 0, startDate: number = 0, targetCalories: number = 0,
    targetProteinG: number = 0, targetSteps: number = 0, trainingFrequencyMin: number = 3,
    trainingFrequencyMax: number = 4, trainingLocation: string = 'gym', dedicatedLegDay: boolean = false,
    preferMachines: boolean = false, status: string = 'active', createdAt: number = 0, updatedAt: number = 0) {
    this.id = id;
    this.goalType = goalType;
    this.startWeightKg = startWeightKg;
    this.targetWeightKg = targetWeightKg;
    this.startDate = startDate;
    this.targetCalories = targetCalories;
    this.targetProteinG = targetProteinG;
    this.targetSteps = targetSteps;
    this.trainingFrequencyMin = trainingFrequencyMin;
    this.trainingFrequencyMax = trainingFrequencyMax;
    this.trainingLocation = trainingLocation;
    this.dedicatedLegDay = dedicatedLegDay;
    this.preferMachines = preferMachines;
    this.status = status;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
  }
}
