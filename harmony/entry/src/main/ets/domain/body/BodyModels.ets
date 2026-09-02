export class BodyMeasurement {
  id: number;
  recordedAt: number;
  weightKg: number;
  waistCm: number;
  bodyFatPercent: number;
  note: string;

  constructor(id: number = 0, recordedAt: number = 0, weightKg: number = 0, waistCm: number = 0,
    bodyFatPercent: number = 0, note: string = '') {
    this.id = id;
    this.recordedAt = recordedAt;
    this.weightKg = weightKg;
    this.waistCm = waistCm;
    this.bodyFatPercent = bodyFatPercent;
    this.note = note;
  }
}
