import { relationalStore } from '@kit.ArkData';
import { BodyMeasurement } from '../../domain/body/BodyModels';
import { AppDatabase } from '../database/AppDatabase';

export class BodyRepository {
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  async addMeasurement(measurement: BodyMeasurement): Promise<BodyMeasurement> {
    if (measurement.weightKg <= 0 && measurement.waistCm <= 0 && measurement.bodyFatPercent <= 0) {
      throw new Error('At least one body measurement is required');
    }
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const recordedAt: number = measurement.recordedAt > 0 ? measurement.recordedAt : Date.now();
    const id: number = await store.insert('body_measurement', {
      recorded_at: recordedAt,
      weight_kg: measurement.weightKg > 0 ? measurement.weightKg : null,
      waist_cm: measurement.waistCm > 0 ? measurement.waistCm : null,
      body_fat_percent: measurement.bodyFatPercent > 0 ? measurement.bodyFatPercent : null,
      note: measurement.note
    });
    return new BodyMeasurement(id, recordedAt, measurement.weightKg, measurement.waistCm,
      measurement.bodyFatPercent, measurement.note);
  }

  async getLatestMeasurement(): Promise<BodyMeasurement | undefined> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const result: relationalStore.ResultSet = await store.querySql(
      `SELECT id, recorded_at, weight_kg, waist_cm, body_fat_percent, note
       FROM body_measurement ORDER BY recorded_at DESC, id DESC LIMIT 1`
    );
    try {
      if (!result.goToFirstRow()) {
        return undefined;
      }
      return this.readMeasurement(result);
    } finally {
      result.close();
    }
  }

  async getMeasurements(startAt: number, endAt: number): Promise<BodyMeasurement[]> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const result: relationalStore.ResultSet = await store.querySql(
      `SELECT id, recorded_at, weight_kg, waist_cm, body_fat_percent, note
       FROM body_measurement WHERE recorded_at >= ? AND recorded_at < ? ORDER BY recorded_at ASC, id ASC`,
      [startAt, endAt]
    );
    const measurements: BodyMeasurement[] = [];
    try {
      if (result.goToFirstRow()) {
        do {
          measurements.push(this.readMeasurement(result));
        } while (result.goToNextRow());
      }
      return measurements;
    } finally {
      result.close();
    }
  }

  private readMeasurement(result: relationalStore.ResultSet): BodyMeasurement {
    return new BodyMeasurement(result.getLong(0), result.getLong(1), result.getDouble(2), result.getDouble(3),
      result.getDouble(4), result.getString(5));
  }
}
