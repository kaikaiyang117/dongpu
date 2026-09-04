import { GoalRepository } from '../data/repository/GoalRepository';
import { ProgramRepository } from '../data/repository/ProgramRepository';
import { WorkoutRepository } from '../data/repository/WorkoutRepository';
import { FitnessGoal } from '../domain/goal/GoalModels';
import {
  ActiveProgramState,
  ProgramWeekStatus,
  ProgramWorkoutCompletion,
  ProgramWorkoutWeekItem,
  ProgramWorkoutV2
} from '../domain/program/ProgramV2Models';
import { TrendService } from './TrendService';

const DEFAULT_PROGRAM_ID: string = 'fat_loss_upper_priority_3_4';

export class ProgramService {
  private goalRepository: GoalRepository;
  private programRepository: ProgramRepository;
  private workoutRepository: WorkoutRepository;

  constructor(context: Context) {
    this.goalRepository = new GoalRepository(context);
    this.programRepository = new ProgramRepository(context);
    this.workoutRepository = new WorkoutRepository(context);
  }

  async loadWeekStatus(now: Date = new Date()): Promise<ProgramWeekStatus> {
    const goal: FitnessGoal | undefined = await this.goalRepository.getActiveGoal();
    const state: ActiveProgramState | undefined = await this.programRepository.getActiveProgramState();
    if (goal === undefined || state === undefined) {
      return new ProgramWeekStatus();
    }
    const programId: string = state.programId === '' ? DEFAULT_PROGRAM_ID : state.programId;
    const workouts: ProgramWorkoutV2[] = await this.programRepository.getWorkouts(programId);
    const range = TrendService.currentWeekRange(now);
    const completions: ProgramWorkoutCompletion[] = await this.workoutRepository.getCompletedProgramWorkouts(
      range.startAt, range.endAt, goal.id, programId);
    const completedIds: Set<string> = new Set<string>();
    completions.forEach((completion: ProgramWorkoutCompletion) => completedIds.add(completion.programWorkoutId));
    const required: ProgramWorkoutV2[] = workouts.filter((workout: ProgramWorkoutV2) => !workout.optional);
    const nextRequiredId: string | undefined = required.find(
      (workout: ProgramWorkoutV2) => !completedIds.has(workout.id))?.id;
    const items: ProgramWorkoutWeekItem[] = workouts.map((workout: ProgramWorkoutV2) => {
      if (completedIds.has(workout.id)) {
        return new ProgramWorkoutWeekItem(workout, workout.optional ? 'optional_completed' : 'completed');
      }
      if (workout.optional) {
        return new ProgramWorkoutWeekItem(workout, 'optional');
      }
      return new ProgramWorkoutWeekItem(workout, workout.id === nextRequiredId ? 'next' : 'pending');
    });
    const requiredCompleted: number = required.filter(
      (workout: ProgramWorkoutV2) => completedIds.has(workout.id)).length;
    return new ProgramWeekStatus(requiredCompleted, required.length, completedIds.has(
      workouts.find((workout: ProgramWorkoutV2) => workout.optional)?.id ?? ''), items);
  }
}
