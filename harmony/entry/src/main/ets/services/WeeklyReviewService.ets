import { ActivityRepository } from '../data/repository/ActivityRepository';
import { BodyRepository } from '../data/repository/BodyRepository';
import { NutritionRepository } from '../data/repository/NutritionRepository';
import { ProgramRepository } from '../data/repository/ProgramRepository';
import { WorkoutRepository } from '../data/repository/WorkoutRepository';
import { DailyActivity } from '../domain/activity/ActivityModels';
import { BodyMeasurement } from '../domain/body/BodyModels';
import { FitnessGoal } from '../domain/goal/GoalModels';
import { ProgramWorkoutV2 } from '../domain/program/ProgramV2Models';
import { NutritionSummary, FoodEntry } from '../domain/nutrition/NutritionModels';
import { ExerciseProgress, WorkoutSession } from '../domain/workout/WorkoutModels';
import { WaistTrend, WeightTrend } from '../domain/progress/ProgressModels';
import { DateRange, TrendService } from './TrendService';

export class WeeklyReviewViewModel {
  weekStartAt: number = 0;
  endAt: number = 0;
  weightTrend: WeightTrend = new WeightTrend();
  waistTrend: WaistTrend = new WaistTrend();
  totalWorkouts: number = 0;
  requiredWorkouts: number = 0;
  optionalWorkouts: number = 0;
  proteinTargetDays: number = 0;
  nutritionLoggedDays: number = 0;
  averageCalories: number = 0;
  averageSteps: number = 0;
  activityLoggedDays: number = 0;
  strengthHighlights: ExerciseProgress[] = [];
}

export class WeeklyReviewService {
  private bodyRepository: BodyRepository;
  private nutritionRepository: NutritionRepository;
  private activityRepository: ActivityRepository;
  private workoutRepository: WorkoutRepository;
  private programRepository: ProgramRepository;

  constructor(context: Context) {
    this.bodyRepository = new BodyRepository(context);
    this.nutritionRepository = new NutritionRepository(context);
    this.activityRepository = new ActivityRepository(context);
    this.workoutRepository = new WorkoutRepository(context);
    this.programRepository = new ProgramRepository(context);
  }

  async load(goal: FitnessGoal | undefined, now: Date = new Date()): Promise<WeeklyReviewViewModel> {
    const range: DateRange = TrendService.currentWeekRange(now);
    const result: WeeklyReviewViewModel = new WeeklyReviewViewModel();
    result.weekStartAt = range.startAt;
    result.endAt = range.endAt;
    const measurements: BodyMeasurement[] = await this.bodyRepository.getMeasurements(
      range.startAt - 27 * 24 * 60 * 60 * 1000, range.endAt);
    result.weightTrend = TrendService.calculateWeightTrend(measurements, now);
    result.waistTrend = TrendService.calculateWaistTrend(measurements, now);

    const entries: FoodEntry[] = await this.nutritionRepository.getFoodEntries(range.startAt, range.endAt);
    const dailyNutrition: Map<string, NutritionSummary> = new Map<string, NutritionSummary>();
    for (const entry of entries) {
      const key: string = TrendService.localDateKey(entry.recordedAt);
      const summary: NutritionSummary = dailyNutrition.get(key) ?? new NutritionSummary();
      summary.calories += entry.calories;
      summary.proteinG += entry.proteinG;
      dailyNutrition.set(key, summary);
    }
    result.nutritionLoggedDays = dailyNutrition.size;
    let totalCalories: number = 0;
    dailyNutrition.forEach((item: NutritionSummary) => totalCalories += item.calories);
    result.averageCalories = result.nutritionLoggedDays > 0 ? totalCalories / result.nutritionLoggedDays : 0;
    if (goal !== undefined && goal.targetProteinG > 0) {
      dailyNutrition.forEach((item: NutritionSummary) => {
        if (item.proteinG >= goal.targetProteinG) result.proteinTargetDays += 1;
      });
    }

    const activities: DailyActivity[] = await this.activityRepository.getRange(
      TrendService.localDateKey(range.startAt), TrendService.localDateKey(range.endAt));
    result.activityLoggedDays = activities.length;
    const totalSteps: number = activities.reduce((total: number, item: DailyActivity) => total + item.steps, 0);
    result.averageSteps = result.activityLoggedDays > 0 ? Math.round(totalSteps / result.activityLoggedDays) : 0;

    const sessions: WorkoutSession[] = await this.workoutRepository.getHistory();
    const weekSessions: WorkoutSession[] = sessions.filter((session: WorkoutSession) =>
      session.completedAt >= range.startAt && session.completedAt < range.endAt);
    result.totalWorkouts = weekSessions.length;
    for (const session of weekSessions) {
      if (session.sourceType === 'program') {
        const workout: ProgramWorkoutV2 | undefined = await this.programRepository.getWorkout(session.programWorkoutId);
        if (workout !== undefined && workout.optional) result.optionalWorkouts += 1;
        else result.requiredWorkouts += 1;
      }
      const highlights: ExerciseProgress[] = await this.workoutRepository.getProgressHighlights(session);
      result.strengthHighlights = result.strengthHighlights.concat(highlights).slice(0, 3);
    }
    return result;
  }

}
