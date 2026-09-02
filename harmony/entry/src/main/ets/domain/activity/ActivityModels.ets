export class DailyActivity {
  dateKey: string;
  steps: number;
  cardioMinutes: number;
  source: string;
  updatedAt: number;

  constructor(dateKey: string = '', steps: number = 0, cardioMinutes: number = 0, source: string = 'manual',
    updatedAt: number = 0) {
    this.dateKey = dateKey;
    this.steps = steps;
    this.cardioMinutes = cardioMinutes;
    this.source = source;
    this.updatedAt = updatedAt;
  }
}
