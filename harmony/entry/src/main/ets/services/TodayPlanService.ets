import { GoalRepository } from '../data/repository/GoalRepository';
import { ProgramRepository } from '../data/repository/ProgramRepository';
import { WorkoutRepository } from '../data/repository/WorkoutRepository';
import { FitnessGoal } from '../domain/goal/GoalModels';
import {
  ActiveProgramState,
  ProgramWorkoutV2,
  ProgramWorkoutWeekItem,
  TodayTrainingPlan,
  TodayTrainingState
} from '../domain/program/ProgramV2Models';
import { WorkoutExerciseRecord, WorkoutSession } from '../domain/workout/WorkoutModels';
import { ProgramService } from './ProgramService';

const DEFAULT_PROGRAM_ID: string = 'fat_loss_upper_priority_3_4';

export class TodayPlanService {
  private goalRepository: GoalRepository;
  private programRepository: ProgramRepository;
  private workoutRepository: WorkoutRepository;
  private programService: ProgramService;

  constructor(context: Context) {
    this.goalRepository = new GoalRepository(context);
    this.programRepository = new ProgramRepository(context);
    this.workoutRepository = new WorkoutRepository(context);
    this.programService = new ProgramService(context);
  }

  async load(now: Date = new Date()): Promise<TodayTrainingPlan> {
    const activeWorkout: WorkoutSession | undefined = await this.workoutRepository.getActiveWorkout();
    const goal: FitnessGoal | undefined = await this.goalRepository.getActiveGoal();
    const state: ActiveProgramState | undefined = await this.programRepository.getActiveProgramState();
    const programId: string = state?.programId === undefined || state.programId === '' ? DEFAULT_PROGRAM_ID : state.programId;
    const workouts: ProgramWorkoutV2[] = await this.programRepository.getWorkouts(programId);
    if (activeWorkout !== undefined) {
      const workout: ProgramWorkoutV2 | undefined = workouts.find(
        (item: ProgramWorkoutV2) => item.id === activeWorkout.programWorkoutId);
      return new TodayTrainingPlan(TodayTrainingState.Active, workout, '训练进行中',
        `${activeWorkout.workoutNameSnapshot} · 已完成 ${activeWorkout.exercises.filter(
          (item: WorkoutExerciseRecord) => item.completedSets >= item.targetSets).length} / ${activeWorkout.exercises.length} 个动作`,
        '正在进行的训练优先于新的训练建议。');
    }
    if (goal === undefined || state === undefined || workouts.length === 0) {
      return new TodayTrainingPlan(TodayTrainingState.Recovery, undefined, '今天建议恢复', '', '完成目标设置后生成训练计划。');
    }
    const weekStatus = await this.programService.loadWeekStatus(now);
    const dayStart: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const dayEnd: number = dayStart.getTime() + 24 * 60 * 60 * 1000;
    const completedToday: boolean = await this.workoutRepository.hasCompletedRequiredToday(
      dayStart.getTime(), dayEnd, goal.id, programId);
    if (completedToday) {
      return new TodayTrainingPlan(TodayTrainingState.Completed, undefined, '今天训练已完成',
        `本周进度 ${weekStatus.requiredCompleted} / ${weekStatus.requiredTarget}`,
        '恢复、正常吃饭和完成步数即可。');
    }
    if (weekStatus.requiredCompleted < weekStatus.requiredTarget) {
      const next = weekStatus.items.find((item: ProgramWorkoutWeekItem) => item.state === 'next');
      return new TodayTrainingPlan(TodayTrainingState.Required, next?.workout, '今天建议',
        next === undefined ? '完成下一场必做训练' : `${next.workout.name} · ${next.workout.focusText}`,
        next === undefined ? '本周还有必做训练待完成。' : `${next.workout.exercises.length} 个动作 · 约 ${next.workout.estimatedMinutes} 分钟`);
    }
    const optional: ProgramWorkoutV2 | undefined = workouts.find((workout: ProgramWorkoutV2) => workout.optional);
    if (goal.trainingFrequencyMax >= 4 && !weekStatus.optionalCompleted && optional !== undefined) {
      return new TodayTrainingPlan(TodayTrainingState.Optional, optional, '本周必做已经完成 ✓',
        `今天可以加练 · ${optional.name}`, '这是可选训练，不做也不会影响本周完成率。');
    }
    return new TodayTrainingPlan(TodayTrainingState.Recovery, undefined, '本周训练已完成 ✓',
      '今天建议恢复', '保持正常步数，完成蛋白质目标，睡够即可。');
  }
}
