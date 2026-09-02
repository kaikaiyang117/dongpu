export class UserProfile {
  id: number;
  heightCm: number;
  sex: string;
  birthYear: number;
  onboardingCompleted: boolean;
  createdAt: number;
  updatedAt: number;

  constructor(id: number = 1, heightCm: number = 0, sex: string = '', birthYear: number = 0,
    onboardingCompleted: boolean = false, createdAt: number = 0, updatedAt: number = 0) {
    this.id = id;
    this.heightCm = heightCm;
    this.sex = sex;
    this.birthYear = birthYear;
    this.onboardingCompleted = onboardingCompleted;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
  }
}

export class OnboardingDraft {
  goalType: string;
  heightCm: number;
  currentWeightKg: number;
  targetWeightKg: number;
  waistCm: number;
  frequencyMin: number;
  frequencyMax: number;
  trainingLocation: string;
  dedicatedLegDay: boolean;
  preferMachines: boolean;
  nutritionMode: string;

  constructor(goalType: string = 'fat_loss', heightCm: number = 170, currentWeightKg: number = 70,
    targetWeightKg: number = 65, waistCm: number = 0, frequencyMin: number = 3, frequencyMax: number = 4,
    trainingLocation: string = 'gym', dedicatedLegDay: boolean = false, preferMachines: boolean = true,
    nutritionMode: string = 'simple') {
    this.goalType = goalType;
    this.heightCm = heightCm;
    this.currentWeightKg = currentWeightKg;
    this.targetWeightKg = targetWeightKg;
    this.waistCm = waistCm;
    this.frequencyMin = frequencyMin;
    this.frequencyMax = frequencyMax;
    this.trainingLocation = trainingLocation;
    this.dedicatedLegDay = dedicatedLegDay;
    this.preferMachines = preferMachines;
    this.nutritionMode = nutritionMode;
  }
}
