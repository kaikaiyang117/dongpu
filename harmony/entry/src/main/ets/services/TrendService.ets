import { BodyMeasurement } from '../domain/body/BodyModels';
import { DailyRepresentativeWeight, WaistTrend, WeightTrend, WeightTrendStatus } from '../domain/progress/ProgressModels';

const DAY_MS: number = 24 * 60 * 60 * 1000;
const MIN_VALID_DAYS: number = 4;

export class TrendService {
  static localDateKey(timestamp: number): string {
    const date: Date = new Date(timestamp);
    const month: string = `${date.getMonth() + 1}`.padStart(2, '0');
    const day: string = `${date.getDate()}`.padStart(2, '0');
    return `${date.getFullYear()}-${month}-${day}`;
  }

  static dailyRepresentativeWeights(measurements: BodyMeasurement[]): DailyRepresentativeWeight[] {
    const sorted: BodyMeasurement[] = measurements
      .filter((measurement: BodyMeasurement) => measurement.weightKg > 0)
      .sort((left: BodyMeasurement, right: BodyMeasurement) => left.recordedAt - right.recordedAt);
    const byDate: Map<string, number> = new Map<string, number>();
    for (const measurement of sorted) {
      byDate.set(TrendService.localDateKey(measurement.recordedAt), measurement.weightKg);
    }
    const values: DailyRepresentativeWeight[] = [];
    byDate.forEach((weightKg: number, dateKey: string) => values.push(
      new DailyRepresentativeWeight(dateKey, weightKg)
    ));
    values.sort((left: DailyRepresentativeWeight, right: DailyRepresentativeWeight) =>
      left.dateKey.localeCompare(right.dateKey));
    return values;
  }

  static calculateWeightTrend(measurements: BodyMeasurement[], now: Date = new Date()): WeightTrend {
    const dailyWeights: DailyRepresentativeWeight[] = TrendService.dailyRepresentativeWeights(measurements);
    const today: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const currentStart: Date = new Date(today.getTime() - 6 * DAY_MS);
    const previousStart: Date = new Date(today.getTime() - 13 * DAY_MS);
    const currentEnd: Date = new Date(today.getTime() + DAY_MS);
    const current = TrendService.windowWeights(dailyWeights, currentStart, currentEnd);
    const previous = TrendService.windowWeights(dailyWeights, previousStart, currentStart);
    if (current.length < MIN_VALID_DAYS || previous.length < MIN_VALID_DAYS) {
      return new WeightTrend(dailyWeights, 0, 0, 0, 0, WeightTrendStatus.Insufficient);
    }
    const currentAverageKg: number = TrendService.average(current);
    const previousAverageKg: number = TrendService.average(previous);
    const changeKg: number = currentAverageKg - previousAverageKg;
    const changePercent: number = previousAverageKg === 0 ? 0 : changeKg / previousAverageKg * 100;
    return new WeightTrend(dailyWeights, currentAverageKg, previousAverageKg, changeKg, changePercent,
      TrendService.statusForChange(changeKg));
  }

  static calculateWaistTrend(measurements: BodyMeasurement[], now: Date = new Date()): WaistTrend {
    const today: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const currentStart: Date = new Date(today.getTime() - 13 * DAY_MS);
    const current: BodyMeasurement[] = measurements.filter((item: BodyMeasurement) => item.waistCm > 0 &&
      item.recordedAt >= currentStart.getTime() && item.recordedAt < today.getTime() + DAY_MS);
    if (current.length === 0) return new WaistTrend();
    const latest: number = current[current.length - 1].waistCm;
    const previous: BodyMeasurement[] = measurements.filter((item: BodyMeasurement) => item.waistCm > 0 &&
      item.recordedAt < currentStart.getTime());
    const previousValue: number = previous.length === 0 ? 0 : previous[previous.length - 1].waistCm;
    return new WaistTrend(latest, previousValue, previousValue === 0 ? 0 : latest - previousValue, true);
  }

  static statusForChange(changeKg: number): WeightTrendStatus {
    // The product spec leaves exact coaching bands open; keep the MVP bands explicit
    // so a later recommendation service can replace them without changing aggregation.
    if (changeKg <= -1) {
      return WeightTrendStatus.Fast;
    }
    if (changeKg <= -0.2) {
      return WeightTrendStatus.Normal;
    }
    return WeightTrendStatus.Slow;
  }

  private static windowWeights(weights: DailyRepresentativeWeight[], start: Date, end: Date): number[] {
    const startKey: string = TrendService.localDateKey(start.getTime());
    const endKey: string = TrendService.localDateKey(end.getTime());
    return weights.filter((item: DailyRepresentativeWeight) => item.dateKey >= startKey && item.dateKey < endKey)
      .map((item: DailyRepresentativeWeight) => item.weightKg);
  }

  private static average(values: number[]): number {
    return values.reduce((total: number, value: number) => total + value, 0) / values.length;
  }
}
