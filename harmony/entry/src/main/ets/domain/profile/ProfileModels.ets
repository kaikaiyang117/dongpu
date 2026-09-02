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
