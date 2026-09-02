export class AppSettings {
  weeklyFrequency: number;
  onboardingCompleted: boolean;
  weightUnit: string;

  constructor(weeklyFrequency: number = 3, onboardingCompleted: boolean = false, weightUnit: string = 'kg') {
    this.weeklyFrequency = weeklyFrequency;
    this.onboardingCompleted = onboardingCompleted;
    this.weightUnit = weightUnit;
  }
}
