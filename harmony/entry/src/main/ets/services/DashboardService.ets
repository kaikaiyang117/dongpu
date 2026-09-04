import { ActivityRepository } from '../data/repository/ActivityRepository';
import { BodyRepository } from '../data/repository/BodyRepository';
import { GoalRepository } from '../data/repository/GoalRepository';
import { NutritionRepository } from '../data/repository/NutritionRepository';
import { WorkoutRepository } from '../data/repository/WorkoutRepository';
import { DailyActivity } from '../domain/activity/ActivityModels';
import { BodyMeasurement } from '../domain/body/BodyModels';
import { FitnessGoal } from '../domain/goal/GoalModels';
import { NutritionSummary } from '../domain/nutrition/NutritionModels';
import { ProgramWorkoutV2, TodayTrainingPlan, TodayTrainingState } from '../domain/program/ProgramV2Models';
import { WaistTrend, WeightTrend } from '../domain/progress/ProgressModels';
import { WorkoutSession } from '../domain/workout/WorkoutModels';
import { TrendService } from './TrendService';
import { TodayPlanService } from './TodayPlanService';

export class DashboardChecklistItem {
  key: string;
  label: string;
  completed: boolean;

  constructor(key: string = '', label: string = '', completed: boolean = false) {
    this.key = key;
    this.label = label;
    this.completed = completed;
  }
}

export class DashboardViewModel {
  goal: FitnessGoal | undefined;
  latestWeight: BodyMeasurement | undefined;
  weightTrend: WeightTrend;
  waistTrend: WaistTrend;
  nutrition: NutritionSummary;
  activity: DailyActivity | undefined;
  todayWorkout: ProgramWorkoutV2 | undefined;
  checklist: DashboardChecklistItem[];
  activeWorkout: WorkoutSession | undefined;
  todayPlan: TodayTrainingPlan;

  constructor(goal: FitnessGoal | undefined = undefined, latestWeight: BodyMeasurement | undefined = undefined,
    weightTrend: WeightTrend = new WeightTrend(), waistTrend: WaistTrend = new WaistTrend(),
    nutrition: NutritionSummary = new NutritionSummary(),
    activity: DailyActivity | undefined = undefined, todayWorkout: ProgramWorkoutV2 | undefined = undefined,
    checklist: DashboardChecklistItem[] = [], activeWorkout: WorkoutSession | undefined = undefined,
    todayPlan: TodayTrainingPlan = new TodayTrainingPlan()) {
    this.goal = goal;
    this.latestWeight = latestWeight;
    this.weightTrend = weightTrend;
    this.waistTrend = waistTrend;
    this.nutrition = nutrition;
    this.activity = activity;
    this.todayWorkout = todayWorkout;
    this.checklist = checklist;
    this.activeWorkout = activeWorkout;
    this.todayPlan = todayPlan;
  }
}

export class DashboardService {
  private goalRepository: GoalRepository;
  private bodyRepository: BodyRepository;
  private nutritionRepository: NutritionRepository;
  private activityRepository: ActivityRepository;
  private workoutRepository: WorkoutRepository;
  private todayPlanService: TodayPlanService;

  constructor(context: Context, todayPlanService: TodayPlanService | undefined = undefined) {
    this.goalRepository = new GoalRepository(context);
    this.bodyRepository = new BodyRepository(context);
    this.nutritionRepository = new NutritionRepository(context);
    this.activityRepository = new ActivityRepository(context);
    this.workoutRepository = new WorkoutRepository(context);
    this.todayPlanService = todayPlanService ?? new TodayPlanService(context);
  }

  async load(now: Date = new Date()): Promise<DashboardViewModel> {
    const dayStart: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const dayEnd: Date = new Date(dayStart.getTime() + 24 * 60 * 60 * 1000);
    const trendStart: Date = new Date(dayStart.getTime() - 29 * 24 * 60 * 60 * 1000);
    const dateKey: string = TrendService.localDateKey(dayStart.getTime());
    const goal: FitnessGoal | undefined = await this.goalRepository.getActiveGoal();
    const latestWeight: BodyMeasurement | undefined = await this.bodyRepository.getLatestMeasurement();
    const measurements: BodyMeasurement[] = await this.bodyRepository.getMeasurements(
      trendStart.getTime(), dayEnd.getTime());
    const nutrition: NutritionSummary = await this.nutritionRepository.getDailySummary(
      dayStart.getTime(), dayEnd.getTime());
    const activity: DailyActivity | undefined = await this.activityRepository.get(dateKey);
    const activeWorkout: WorkoutSession | undefined = await this.workoutRepository.getActiveWorkout();
    const todayPlan: TodayTrainingPlan = await this.todayPlanService.load(now);
    const todayWorkout: ProgramWorkoutV2 | undefined = todayPlan.workout;
    const weightTrend: WeightTrend = TrendService.calculateWeightTrend(measurements, now);
    const waistTrend: WaistTrend = TrendService.calculateWaistTrend(measurements, now);
    const checklist: DashboardChecklistItem[] = this.buildChecklist(goal, latestWeight, dayStart, nutrition, activity,
      todayPlan.state === TodayTrainingState.Completed);
    return new DashboardViewModel(goal, latestWeight, weightTrend, waistTrend, nutrition, activity, todayWorkout, checklist,
      activeWorkout, todayPlan);
  }

  private buildChecklist(goal: FitnessGoal | undefined, latestWeight: BodyMeasurement | undefined, dayStart: Date,
    nutrition: NutritionSummary, activity: DailyActivity | undefined,
    workoutDone: boolean): DashboardChecklistItem[] {
    const hasWeightToday: boolean = latestWeight !== undefined && latestWeight.recordedAt >= dayStart.getTime() &&
      latestWeight.recordedAt < dayStart.getTime() + 24 * 60 * 60 * 1000;
    const nutritionStarted: boolean = nutrition.calories > 0 || nutrition.proteinG > 0;
    const proteinTarget: number = goal?.targetProteinG ?? 0;
    const stepsTarget: number = goal?.targetSteps ?? 0;
    return [
      new DashboardChecklistItem('weight', '记录晨重', hasWeightToday),
      new DashboardChecklistItem('nutrition', '饮食记录已开始', nutritionStarted),
      new DashboardChecklistItem('protein', '蛋白质目标', proteinTarget > 0 && nutrition.proteinG >= proteinTarget),
      new DashboardChecklistItem('steps', '步数目标', stepsTarget > 0 && (activity?.steps ?? 0) >= stepsTarget),
      new DashboardChecklistItem('workout', '今日训练', workoutDone)
    ];
  }
}
