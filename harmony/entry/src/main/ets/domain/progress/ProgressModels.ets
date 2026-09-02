export enum WeightTrendStatus {
  Insufficient = 'insufficient',
  Slow = 'slow',
  Normal = 'normal',
  Fast = 'fast'
}

export class DailyRepresentativeWeight {
  dateKey: string;
  weightKg: number;

  constructor(dateKey: string = '', weightKg: number = 0) {
    this.dateKey = dateKey;
    this.weightKg = weightKg;
  }
}

export class WeightTrend {
  dailyWeights: DailyRepresentativeWeight[];
  currentAverageKg: number;
  previousAverageKg: number;
  changeKg: number;
  changePercent: number;
  status: WeightTrendStatus;

  constructor(dailyWeights: DailyRepresentativeWeight[] = [], currentAverageKg: number = 0,
    previousAverageKg: number = 0, changeKg: number = 0, changePercent: number = 0,
    status: WeightTrendStatus = WeightTrendStatus.Insufficient) {
    this.dailyWeights = dailyWeights;
    this.currentAverageKg = currentAverageKg;
    this.previousAverageKg = previousAverageKg;
    this.changeKg = changeKg;
    this.changePercent = changePercent;
    this.status = status;
  }
}
