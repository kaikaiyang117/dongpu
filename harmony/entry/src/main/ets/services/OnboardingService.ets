import { ProfileRepository } from '../data/repository/ProfileRepository';
import { GoalRepository } from '../data/repository/GoalRepository';
import { ProgramRepository } from '../data/repository/ProgramRepository';
import { SettingsRepository } from '../data/repository/SettingsRepository';
import { UserProfile } from '../domain/profile/ProfileModels';
import { FitnessGoal } from '../domain/goal/GoalModels';
import { ActiveProgramState, TrainingProgram } from '../domain/program/ProgramV2Models';

export class V2Readiness {
  profileReady: boolean;
  goalReady: boolean;
  programReady: boolean;
  ready: boolean;

  constructor(profileReady: boolean = false, goalReady: boolean = false, programReady: boolean = false) {
    this.profileReady = profileReady;
    this.goalReady = goalReady;
    this.programReady = programReady;
    this.ready = profileReady && goalReady && programReady;
  }
}

export class OnboardingService {
  private profileRepository: ProfileRepository;
  private goalRepository: GoalRepository;
  private programRepository: ProgramRepository;
  private settingsRepository: SettingsRepository;

  constructor(context: Context) {
    this.profileRepository = new ProfileRepository(context);
    this.goalRepository = new GoalRepository(context);
    this.programRepository = new ProgramRepository(context);
    this.settingsRepository = new SettingsRepository(context);
  }

  async getReadiness(): Promise<V2Readiness> {
    const profile: UserProfile | undefined = await this.profileRepository.getProfile();
    const goal: FitnessGoal | undefined = await this.goalRepository.getActiveGoal();
    const state: ActiveProgramState | undefined = await this.programRepository.getActiveProgramState();
    const profileReady: boolean = profile !== undefined && profile.onboardingCompleted;
    const goalReady: boolean = goal !== undefined && goal.id > 0;
    const program: TrainingProgram | undefined = state === undefined ? undefined :
      await this.programRepository.getProgram(state.programId);
    const programReady: boolean = state !== undefined && goal !== undefined && state.goalId === goal.id &&
      state.programId !== '' && program !== undefined;
    return new V2Readiness(profileReady, goalReady, programReady);
  }

  async isLegacyOnboardingCompleted(): Promise<boolean> {
    const settings = await this.settingsRepository.getSettings();
    return settings.onboardingCompleted;
  }

  static caloriesForWeight(weightKg: number, frequency: number): number {
    return Math.max(1400, Math.round(weightKg * 28 - 300 + (frequency - 3) * 50));
  }

  static proteinForWeight(weightKg: number): number {
    return Math.round(weightKg * 1.8);
  }
}
