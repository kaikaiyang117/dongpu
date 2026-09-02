import { APP_COLOR_BG } from './AppTheme';
import { AppRoute } from './AppRoutes';
import { AppHeader } from '../components/AppHeader';
import { BottomNav } from '../components/BottomNav';
import { exerciseMatchesPart, findExercise, findExerciseExact, getGymEligibleApprovedExercises, loadExercises, userPartId } from '../data/ExerciseCatalog';
import { PlanRepository } from '../data/repository/PlanRepository';
import { ActivityRepository } from '../data/repository/ActivityRepository';
import { BodyRepository } from '../data/repository/BodyRepository';
import { GoalRepository } from '../data/repository/GoalRepository';
import { ProfileRepository } from '../data/repository/ProfileRepository';
import { SettingsRepository } from '../data/repository/SettingsRepository';
import { WorkoutRepository } from '../data/repository/WorkoutRepository';
import { NutritionRepository } from '../data/repository/NutritionRepository';
import { ProgramRepository } from '../data/repository/ProgramRepository';
import { DashboardService, DashboardViewModel } from '../services/DashboardService';
import { ProgramExercise, ProgramWorkout, recommendedWorkout } from '../domain/program/ProgramModels';
import { WorkoutExerciseRecord, WorkoutPhase, WorkoutSession, WorkoutStatus, ExerciseProgress } from '../domain/workout/WorkoutModels';
import { CustomTrainingFlow } from '../features/custom/CustomTrainingFlow';
import { DashboardPage } from '../features/dashboard/DashboardPage';
import { ExerciseDetailPage } from '../features/exercise/ExerciseDetailPage';
import { ExerciseLibraryPage } from '../features/exercise/ExerciseLibraryPage';
import { HistoryPage } from '../features/history/HistoryPage';
import { WorkoutHistoryDetailPage } from '../features/history/WorkoutHistoryDetailPage';
import { OnboardingPage } from '../features/onboarding/OnboardingPage';
import { SettingsPage } from '../features/settings/SettingsPage';
import { TrainingHomePage } from '../features/training/TrainingHomePage';
import { ExerciseCompletedPage } from '../features/training/ExerciseCompletedPage';
import { ExerciseAlternativePage } from '../features/training/ExerciseAlternativePage';
import { ExitWorkoutPage } from '../features/training/ExitWorkoutPage';
import { RestPage } from '../features/training/RestPage';
import { WorkoutCompletePage } from '../features/training/WorkoutCompletePage';
import { WorkoutPage } from '../features/training/WorkoutPage';
import { WorkoutPreviewPage } from '../features/training/WorkoutPreviewPage';
import { NutritionPage } from '../features/nutrition/NutritionPage';
import { FoodEntryEditorPage } from '../features/nutrition/FoodEntryEditorPage';
import { ProgressPage } from '../features/progress/ProgressPage';
import { BodyQuickEntryPage } from '../features/progress/BodyQuickEntryPage';
import { Exercise } from '../model/Exercise';
import { PlanItem } from '../model/WorkoutData';
import { ActiveProgramState, ProgramWorkoutV2 } from '../domain/program/ProgramV2Models';
import { OnboardingDraft, UserProfile } from '../domain/profile/ProfileModels';
import { FitnessGoal } from '../domain/goal/GoalModels';
import { BodyMeasurement } from '../domain/body/BodyModels';
import { FoodEntry, NutritionSummary, QuickFood } from '../domain/nutrition/NutritionModels';

@Component
export struct AppRoot {
  @State exercises: Exercise[] = [];
  @State route: AppRoute = AppRoute.Loading;
  @State weeklyFrequency: number = 2;
  @State selectedFrequency: number = 2;
  @State weeklyCompleted: number = 0;
  @State nextWorkoutCode: string = 'A';
  @State weightUnit: string = 'kg';
  @State activeGoal: FitnessGoal = new FitnessGoal();
  @State isSaving: boolean = false;
  @State hasActiveWorkout: boolean = false;
  @State activeCompletedExercises: number = 0;
  @State activeMinutes: number = 0;
  @State activeSession: WorkoutSession | undefined = undefined;
  @State completedSession: WorkoutSession | undefined = undefined;
  @State progressHighlights: ExerciseProgress[] = [];
  @State historySessions: WorkoutSession[] = [];
  @State detailSessionId: number = 0;
  @State operationError: string = '';
  @State dashboard: DashboardViewModel = new DashboardViewModel();
  @State nutritionSummary: NutritionSummary = new NutritionSummary();
  @State nutritionQuickFoods: QuickFood[] = [];
  @State nutritionEntries: FoodEntry[] = [];
  @State programName: string = '';
  @State programWeek: number = 1;
  @State programWorkouts: ProgramWorkout[] = [];
  @State nextRequiredWorkoutIndex: number = 0;
  @State previewWorkoutCode: string = '';
  @State customPlanSaved: boolean = false;
  @State libraryFromTab: boolean = false;
  @State selectedParts: string[] = ['chest'];
  @State selectedExerciseIds: string[] = [];
  @State planItems: PlanItem[] = [];
  @State savedPlanItems: PlanItem[] = [];
  @State libraryPartId: string = 'chest';
  @State libraryEquipment: string = '全部';
  @State detailExerciseId: string = '';
  private settingsRepository: SettingsRepository | undefined;
  private workoutRepository: WorkoutRepository | undefined;
  private planRepository: PlanRepository | undefined;
  private profileRepository: ProfileRepository | undefined;
  private goalRepository: GoalRepository | undefined;
  private bodyRepository: BodyRepository | undefined;
  private nutritionRepository: NutritionRepository | undefined;
  private programRepository: ProgramRepository | undefined;
  private programWorkoutRecords: ProgramWorkoutV2[] = [];
  private dashboardService: DashboardService | undefined;
  private programCatalogValid: boolean = false;

  aboutToAppear(): void {
    const hostContext = this.getUIContext().getHostContext();
    if (hostContext !== undefined) {
      this.exercises = loadExercises(hostContext.resourceManager);
      this.validateProgramCatalog();
      this.settingsRepository = new SettingsRepository(hostContext);
      this.workoutRepository = new WorkoutRepository(hostContext);
      this.planRepository = new PlanRepository(hostContext);
      this.profileRepository = new ProfileRepository(hostContext);
      this.goalRepository = new GoalRepository(hostContext);
      this.bodyRepository = new BodyRepository(hostContext);
      this.nutritionRepository = new NutritionRepository(hostContext);
      this.programRepository = new ProgramRepository(hostContext);
      this.dashboardService = new DashboardService(hostContext);
      this.initializeApp();
    }
  }

  private async initializeApp(): Promise<void> {
    if (this.settingsRepository === undefined || this.workoutRepository === undefined ||
      this.profileRepository === undefined) {
      return;
    }
    try {
      const settings = await this.settingsRepository.getSettings();
      const profile: UserProfile | undefined = await this.profileRepository.getProfile();
      const programState = await this.workoutRepository.getProgramState();
      const activeWorkout: WorkoutSession | undefined = await this.workoutRepository.getActiveWorkout();
      await this.loadCustomPlan();
      this.weeklyFrequency = settings.weeklyFrequency;
      this.selectedFrequency = settings.weeklyFrequency;
      this.weightUnit = settings.weightUnit;
      if (this.goalRepository !== undefined) {
        this.activeGoal = await this.goalRepository.getActiveGoal() ?? new FitnessGoal();
      }
      this.weeklyCompleted = programState.weeklyCompleted;
      this.nextWorkoutCode = programState.nextWorkoutCode;
      this.applyActiveWorkout(activeWorkout);
      if (profile?.onboardingCompleted ?? settings.onboardingCompleted) {
        await this.loadActiveProgram();
        await this.refreshDashboard();
        this.route = AppRoute.Dashboard;
      } else {
        this.route = AppRoute.Onboarding;
      }
    } catch (_) {
      this.route = AppRoute.Onboarding;
    }
  }

  private async refreshDashboard(): Promise<void> {
    if (this.dashboardService === undefined) {
      return;
    }
    this.dashboard = await this.dashboardService.load();
  }

  private async refreshNutrition(): Promise<void> {
    if (this.nutritionRepository === undefined) {
      return;
    }
    const now: Date = new Date();
    const dayStart: number = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    const dayEnd: number = dayStart + 24 * 60 * 60 * 1000;
    this.nutritionSummary = await this.nutritionRepository.getDailySummary(dayStart, dayEnd);
    this.nutritionQuickFoods = await this.nutritionRepository.getQuickFoods();
    this.nutritionEntries = await this.nutritionRepository.getFoodEntries(dayStart, dayEnd);
  }

  private async loadActiveProgram(): Promise<void> {
    if (this.programRepository === undefined) {
      return;
    }
    let state: ActiveProgramState | undefined = await this.programRepository.getActiveProgramState();
    if (state === undefined && this.goalRepository !== undefined) {
      const goal: FitnessGoal | undefined = await this.goalRepository.getActiveGoal();
      if (goal !== undefined) {
        state = await this.programRepository.saveActiveProgramState(new ActiveProgramState(
          1, goal.id, 'fat_loss_upper_priority_3_4', '1.0', Date.now(), 1, 0
        ));
      }
    }
    if (state === undefined) {
      state = new ActiveProgramState(1, 0, 'fat_loss_upper_priority_3_4', '1.0', Date.now(), 1, 0);
    }
    const programId: string = state.programId === '' ? 'fat_loss_upper_priority_3_4' : state.programId;
    const program = await this.programRepository.getProgram(programId);
    const records: ProgramWorkoutV2[] = await this.programRepository.getWorkouts(programId);
    this.programWorkoutRecords = records;
    this.programWorkouts = records.map((item: ProgramWorkoutV2) => this.toProgramWorkout(item));
    this.programName = program?.name ?? '';
    this.programWeek = state.currentWeek;
    this.nextRequiredWorkoutIndex = state.nextRequiredWorkoutIndex;
    this.programCatalogValid = this.programWorkouts.length > 0 && this.programWorkouts.every(
      (workout: ProgramWorkout) => workout.exercises.length > 0 && workout.exercises.every(
        (item: ProgramExercise) => findExerciseExact(this.exercises, item.exerciseId) !== undefined
      )
    );
  }

  private toProgramWorkout(record: ProgramWorkoutV2): ProgramWorkout {
    const exercises: ProgramExercise[] = record.exercises.map((item) => {
      const catalogExercise: Exercise | undefined = findExerciseExact(this.exercises, item.exerciseId);
      if (catalogExercise === undefined) {
        return new ProgramExercise(item.exerciseId, item.exerciseId, '', '', '', item.plannedSets,
          item.repMin, item.repMax, item.restSeconds);
      }
      return new ProgramExercise(catalogExercise.id, catalogExercise.name, this.userPartName(catalogExercise),
        catalogExercise.equipment, catalogExercise.imagePath, item.plannedSets, item.repMin, item.repMax,
        item.restSeconds);
    });
    return new ProgramWorkout(record.code, record.name, record.estimatedMinutes, exercises);
  }

  private requiredProgramWorkouts(): ProgramWorkout[] {
    return this.programWorkouts.filter((workout: ProgramWorkout) => workout.code !== 'optional_arms');
  }

  private nextRequiredProgramWorkout(): ProgramWorkout | undefined {
    const required: ProgramWorkout[] = this.requiredProgramWorkouts();
    if (required.length === 0) {
      return undefined;
    }
    return required[Math.min(this.nextRequiredWorkoutIndex, required.length - 1)];
  }

  private workoutForCode(code: string): ProgramWorkout | undefined {
    return this.programWorkouts.find((workout: ProgramWorkout) => workout.code === code);
  }

  private previewWorkout(): ProgramWorkout {
    return this.workoutForCode(this.previewWorkoutCode) ?? this.nextRequiredProgramWorkout() ?? this.currentWorkout();
  }

  private openRequiredPreview(): void {
    this.previewWorkoutCode = this.nextRequiredProgramWorkout()?.code ?? '';
    this.route = AppRoute.WorkoutPreview;
  }

  private openProgramPreview(code: string): void {
    this.previewWorkoutCode = code;
    this.route = AppRoute.WorkoutPreview;
  }

  private defaultMealType(): string {
    const hour: number = new Date().getHours();
    const minutes: number = new Date().getMinutes();
    const clock: number = hour * 60 + minutes;
    if (clock >= 5 * 60 && clock < 10 * 60 + 30) return 'breakfast';
    if (clock >= 10 * 60 + 30 && clock < 14 * 60 + 30) return 'lunch';
    if (clock >= 17 * 60 + 30 && clock < 22 * 60 + 30) return 'dinner';
    return 'snack';
  }

  private async openNutrition(): Promise<void> {
    await this.refreshNutrition();
    this.route = AppRoute.Nutrition;
  }

  private async addQuickFood(quickFoodId: number): Promise<void> {
    if (this.nutritionRepository === undefined || this.isSaving) {
      return;
    }
    this.isSaving = true;
    try {
      await this.nutritionRepository.addQuickFoodEntry(quickFoodId, this.defaultMealType(), 1, Date.now());
      await this.refreshNutrition();
      await this.refreshDashboard();
      this.route = AppRoute.Dashboard;
    } catch (_) {
      this.operationError = '营养记录保存失败，请稍后重试';
    } finally {
      this.isSaving = false;
    }
  }

  private async saveFoodEntry(entry: FoodEntry): Promise<void> {
    if (this.nutritionRepository === undefined || this.isSaving) {
      return;
    }
    this.isSaving = true;
    try {
      await this.nutritionRepository.addFoodEntry(entry);
      await this.refreshNutrition();
      await this.refreshDashboard();
      this.route = AppRoute.Dashboard;
    } catch (_) {
      this.operationError = '营养记录保存失败，请检查输入';
    } finally {
      this.isSaving = false;
    }
  }

  private async saveBodyMeasurement(measurement: BodyMeasurement): Promise<void> {
    if (this.bodyRepository === undefined || this.isSaving) return;
    this.isSaving = true;
    try {
      await this.bodyRepository.addMeasurement(measurement);
      await this.refreshDashboard();
      this.route = AppRoute.Dashboard;
    } catch (_) {
      this.operationError = '身体记录保存失败，请检查输入';
    } finally {
      this.isSaving = false;
    }
  }

  private async loadCustomPlan(): Promise<void> {
    if (this.planRepository === undefined) {
      return;
    }
    const draft = await this.planRepository.getDraftPlan();
    const saved = await this.planRepository.getSavedPlan();
    const plan = draft ?? saved;
    this.customPlanSaved = saved !== undefined;
    this.savedPlanItems = saved?.exercises.map((item) => new PlanItem(
      item.exerciseId, item.sets, item.repMin, item.repMax, item.restSeconds
    )) ?? [];
    if (plan === undefined) {
      return;
    }
    const availableIds: string[] = this.exercises.map((exercise: Exercise) => exercise.id);
    this.planItems = plan.exercises
      .filter((item) => availableIds.includes(item.exerciseId))
      .map((item) => new PlanItem(
        item.exerciseId, item.sets, item.repMin, item.repMax, item.restSeconds
      ));
    this.selectedExerciseIds = this.planItems.map((item: PlanItem) => item.exerciseId);
    this.selectedParts = [];
    this.planItems.forEach((item: PlanItem) => {
      const partId: string = userPartId(findExercise(this.exercises, item.exerciseId));
      if (!this.selectedParts.includes(partId)) {
        this.selectedParts = [...this.selectedParts, partId];
      }
    });
  }

  private applyActiveWorkout(session: WorkoutSession | undefined): void {
    this.activeSession = session;
    this.hasActiveWorkout = session !== undefined;
    if (session === undefined) {
      this.activeCompletedExercises = 0;
      this.activeMinutes = 0;
      return;
    }
    this.activeCompletedExercises = session.exercises.filter((item) => item.completedSets >= item.targetSets).length;
    this.activeMinutes = Math.max(1, Math.floor((Date.now() - session.startedAt) / 60000));
  }

  private currentWorkout(): ProgramWorkout {
    const programWorkout: ProgramWorkout | undefined = this.nextRequiredProgramWorkout();
    if (programWorkout !== undefined) {
      return programWorkout;
    }
    const template: ProgramWorkout = recommendedWorkout(this.nextWorkoutCode);
    const exercises: ProgramExercise[] = template.exercises.map((item: ProgramExercise) => {
      const catalogExercise: Exercise | undefined = findExerciseExact(this.exercises, item.exerciseId);
      if (catalogExercise === undefined) {
        return item;
      }
      return new ProgramExercise(
        catalogExercise.id,
        catalogExercise.name,
        this.userPartName(catalogExercise),
        catalogExercise.equipment,
        catalogExercise.imagePath,
        item.sets,
        item.repMin,
        item.repMax,
        item.restSeconds
      );
    });
    return new ProgramWorkout(template.code, template.name, template.estimatedMinutes, exercises);
  }

  private userPartName(exercise: Exercise): string {
    const partId: string = userPartId(exercise);
    if (partId === 'chest') return '胸部';
    if (partId === 'back') return '背部';
    if (partId === 'shoulders') return '肩部';
    if (partId === 'arms') return '手臂';
    if (partId === 'legs') return '腿部';
    if (partId === 'core') return '核心';
    return partId;
  }

  private validateProgramCatalog(): void {
    this.programCatalogValid = false;
    const codes: string[] = ['A', 'B'];
    for (const code of codes) {
      const workout: ProgramWorkout = recommendedWorkout(code);
      for (const item of workout.exercises) {
        const exercise: Exercise | undefined = findExerciseExact(this.exercises, item.exerciseId);
        if (exercise === undefined || exercise.contentReviewStatus !== 'approved' ||
          !exercise.gymEligible || !exercise.recommendedForBeginner) {
          this.operationError = '推荐训练数据校验失败，请更新动作目录';
          return;
        }
      }
    }
    this.programCatalogValid = true;
  }

  private currentActiveExercise(): WorkoutExerciseRecord {
    const session: WorkoutSession = this.activeSession as WorkoutSession;
    return session.exercises[session.currentExerciseIndex];
  }

  private completedSetCount(): number {
    if (this.completedSession === undefined) {
      return 0;
    }
    return this.completedSession.exercises.reduce((total: number, item: WorkoutExerciseRecord) =>
      total + item.completedSets, 0);
  }

  private completedMinutes(): number {
    if (this.completedSession === undefined) {
      return 0;
    }
    return Math.max(1, Math.floor((Date.now() - this.completedSession.startedAt) / 60000));
  }

  private openActiveWorkout(): void {
    if (this.activeSession === undefined) {
      this.route = AppRoute.Dashboard;
      return;
    }
    if (this.activeSession.phase === WorkoutPhase.Rest) {
      this.route = AppRoute.Rest;
    } else if (this.activeSession.phase === WorkoutPhase.ExerciseCompleted) {
      this.route = AppRoute.ExerciseCompleted;
    } else {
      this.route = AppRoute.Workout;
    }
  }

  private async completeOnboarding(draft: OnboardingDraft): Promise<void> {
    if (this.settingsRepository === undefined || this.profileRepository === undefined ||
      this.goalRepository === undefined || this.bodyRepository === undefined || this.isSaving) {
      return;
    }
    this.isSaving = true;
    try {
      const now: number = Date.now();
      const calories: number = Math.max(1400, Math.round(draft.currentWeightKg * 28 - 300 +
        (draft.frequencyMax - 3) * 50));
      const protein: number = Math.round(draft.currentWeightKg * 1.8);
      const profile: UserProfile = new UserProfile(1, draft.heightCm, '', 0, false, now, now);
      await this.profileRepository.saveProfile(profile);
      await this.bodyRepository.addMeasurement(new BodyMeasurement(0, now, draft.currentWeightKg, draft.waistCm,
        0, 'onboarding'));
      const goal: FitnessGoal = await this.goalRepository.saveActiveGoal(new FitnessGoal(
        0, draft.goalType, draft.currentWeightKg, draft.targetWeightKg, now, calories, protein, 8000,
        draft.frequencyMin, draft.frequencyMax, draft.trainingLocation, draft.dedicatedLegDay,
        draft.preferMachines, 'active', now, now
      ));
      await this.goalRepository.saveActiveProgramState(new ActiveProgramState(
        1, goal.id, 'fat_loss_upper_priority_3_4', '1.0', now, 1, 0
      ));
      await this.profileRepository.setOnboardingCompleted(true);
      await this.settingsRepository.completeOnboarding(draft.frequencyMin);
      this.weeklyFrequency = draft.frequencyMin;
      this.selectedFrequency = draft.frequencyMin;
      await this.loadActiveProgram();
      this.activeGoal = goal;
      await this.refreshDashboard();
      this.route = AppRoute.Dashboard;
    } finally {
      this.isSaving = false;
    }
  }

  private async changeWeeklyFrequency(frequency: number): Promise<void> {
    if (this.settingsRepository === undefined) {
      return;
    }
    await this.settingsRepository.updateWeeklyFrequency(frequency);
    if (this.goalRepository !== undefined && this.activeGoal.id > 0) {
      await this.goalRepository.updateActiveTrainingPreference(frequency, this.activeGoal.trainingLocation,
        this.activeGoal.dedicatedLegDay, this.activeGoal.preferMachines);
      this.activeGoal = await this.goalRepository.getActiveGoal() ?? this.activeGoal;
      await this.refreshDashboard();
    }
    this.weeklyFrequency = frequency;
  }

  private async changeWeightUnit(unit: string): Promise<void> {
    if (this.settingsRepository === undefined) {
      return;
    }
    await this.settingsRepository.updateWeightUnit(unit);
    this.weightUnit = unit;
  }

  private async saveGoalTargets(targetCalories: number, targetProteinG: number, targetSteps: number): Promise<void> {
    if (this.goalRepository === undefined || this.isSaving || this.activeGoal.id <= 0) return;
    this.isSaving = true;
    try {
      await this.goalRepository.updateActiveTargets(targetCalories, targetProteinG, targetSteps);
      this.activeGoal = await this.goalRepository.getActiveGoal() ?? this.activeGoal;
      await this.refreshDashboard();
    } catch (_) {
      this.operationError = '目标保存失败，请检查输入';
    } finally {
      this.isSaving = false;
    }
  }

  private async changeTrainingPreference(location: string, dedicatedLegDay: boolean,
    preferMachines: boolean): Promise<void> {
    if (this.goalRepository === undefined || this.isSaving || this.activeGoal.id <= 0) return;
    this.isSaving = true;
    try {
      await this.goalRepository.updateActiveTrainingPreference(this.weeklyFrequency, location, dedicatedLegDay,
        preferMachines);
      this.activeGoal = await this.goalRepository.getActiveGoal() ?? this.activeGoal;
      await this.refreshDashboard();
    } catch (_) {
      this.operationError = '训练偏好保存失败，请稍后重试';
    } finally {
      this.isSaving = false;
    }
  }

  private async startRecommendedWorkout(): Promise<void> {
    if (this.workoutRepository === undefined || this.isSaving || !this.programCatalogValid) {
      this.operationError = '训练计划数据校验失败，请更新动作目录';
      return;
    }
    this.isSaving = true;
    try {
      const workout: ProgramWorkout = this.previewWorkout();
      const record: ProgramWorkoutV2 | undefined = this.programWorkoutRecords.find(
        (item: ProgramWorkoutV2) => item.code === workout.code
      );
      const session: WorkoutSession = record !== undefined && this.programRepository !== undefined ?
        await this.workoutRepository.startProgramWorkout(workout, record.programId, record.id, '1.0',
          (await this.programRepository.getActiveProgramState())?.goalId ?? 0) :
        await this.workoutRepository.startRecommendedWorkout(workout);
      this.applyActiveWorkout(session);
      this.openActiveWorkout();
    } finally {
      this.isSaving = false;
    }
  }

  private customWorkout(items: PlanItem[] = this.planItems): ProgramWorkout {
    const programExercises: ProgramExercise[] = items.map((item: PlanItem) => {
      const exercise: Exercise = findExercise(this.exercises, item.exerciseId);
      return new ProgramExercise(
        exercise.id, exercise.name, this.userPartName(exercise), exercise.equipment, exercise.imagePath,
        item.sets, item.repMin, item.repMax, item.restSeconds
      );
    });
    return new ProgramWorkout('自定义', '自定义训练', Math.max(20, items.length * 7), programExercises);
  }

  private async startCustomWorkout(): Promise<void> {
    if (this.workoutRepository === undefined || this.planItems.length === 0 || this.isSaving) {
      return;
    }
    this.isSaving = true;
    try {
      if (this.planRepository !== undefined) {
        await this.planRepository.saveDraft(this.planItems);
      }
      const session: WorkoutSession = await this.workoutRepository.startAdHocWorkout(this.customWorkout());
      this.applyActiveWorkout(session);
      this.openActiveWorkout();
    } catch (_) {
      this.operationError = '无法开始训练，请重试';
    } finally {
      this.isSaving = false;
    }
  }

  private async startSavedPlanWorkout(): Promise<void> {
    if (this.workoutRepository === undefined || this.isSaving) {
      return;
    }
    this.isSaving = true;
    this.operationError = '';
    try {
      let savedItems: PlanItem[] = this.savedPlanItems;
      if (this.planRepository !== undefined) {
        const saved = await this.planRepository.getSavedPlan();
        savedItems = saved?.exercises.map((item) => new PlanItem(
          item.exerciseId, item.sets, item.repMin, item.repMax, item.restSeconds
        )) ?? [];
      }
      if (savedItems.length === 0) {
        this.operationError = '还没有可开始的我的计划';
        return;
      }
      const session: WorkoutSession = await this.workoutRepository.startSavedPlanWorkout(this.customWorkout(savedItems));
      this.applyActiveWorkout(session);
      this.openActiveWorkout();
    } catch (_) {
      this.operationError = '无法开始我的计划，请重试';
    } finally {
      this.isSaving = false;
    }
  }


  private async completeActiveSet(weight: number, reps: number): Promise<void> {
    if (this.workoutRepository === undefined || this.activeSession === undefined || this.isSaving) {
      return;
    }
    this.isSaving = true;
    this.operationError = '';
    try {
      const session: WorkoutSession = await this.workoutRepository.completeSet(this.activeSession, weight, reps);
      this.applyActiveWorkout(session);
      if (session.phase === WorkoutPhase.Complete) {
        await this.finishActiveWorkout();
      } else {
        this.openActiveWorkout();
      }
    } catch (_) {
      this.operationError = '保存失败，请重试';
    } finally {
      this.isSaving = false;
    }
  }

  private async finishActiveRest(): Promise<void> {
    if (this.workoutRepository === undefined || this.activeSession === undefined) {
      return;
    }
    const session: WorkoutSession = await this.workoutRepository.finishRest(this.activeSession.id);
    this.applyActiveWorkout(session);
    this.route = AppRoute.Workout;
  }

  private async adjustActiveRest(deltaSeconds: number): Promise<void> {
    if (this.workoutRepository === undefined || this.activeSession === undefined) {
      return;
    }
    const session: WorkoutSession = await this.workoutRepository.adjustRest(this.activeSession, deltaSeconds);
    this.applyActiveWorkout(session);
  }

  private async startNextActiveExercise(): Promise<void> {
    if (this.workoutRepository === undefined || this.activeSession === undefined) {
      return;
    }
    const session: WorkoutSession = await this.workoutRepository.startNextExercise(this.activeSession);
    this.applyActiveWorkout(session);
    this.route = AppRoute.Workout;
  }

  private alternativePartId(): string {
    const partName: string = this.currentActiveExercise().partNameSnapshot;
    if (partName === 'chest' || partName.includes('胸')) return 'chest';
    if (partName === 'back' || partName.includes('背')) return 'back';
    if (partName === 'shoulders' || partName.includes('肩')) return 'shoulders';
    if (partName === 'arms' || partName.includes('手') || partName.includes('臂')) return 'arms';
    if (partName === 'core' || partName.includes('核') || partName.includes('腰')) return 'core';
    return 'legs';
  }

  private alternatives(): Exercise[] {
    if (this.activeSession === undefined) {
      return [];
    }
    const currentId: string = this.currentActiveExercise().actualExerciseId;
    return getGymEligibleApprovedExercises(this.exercises).filter((exercise: Exercise) =>
      exercise.id !== currentId && exerciseMatchesPart(exercise, this.alternativePartId())).slice(0, 2);
  }

  private async replaceActiveExercise(exerciseId: string): Promise<void> {
    if (this.workoutRepository === undefined || this.activeSession === undefined) {
      return;
    }
    if (this.currentActiveExercise().completedSets > 0) {
      this.operationError = '已记录的动作不能替换';
      this.route = AppRoute.Workout;
      return;
    }
    const exercise: Exercise = findExercise(this.exercises, exerciseId);
    const replacement: ProgramExercise = new ProgramExercise(
      exercise.id, exercise.name, this.currentActiveExercise().partNameSnapshot, exercise.equipment,
      exercise.imagePath
    );
    const session: WorkoutSession = await this.workoutRepository.replaceCurrentExercise(this.activeSession,
      replacement);
    this.applyActiveWorkout(session);
    this.route = AppRoute.Workout;
  }

  private async moveActiveExerciseToEnd(): Promise<void> {
    if (this.workoutRepository === undefined || this.activeSession === undefined) {
      return;
    }
    const session: WorkoutSession = await this.workoutRepository.moveCurrentExerciseToEnd(this.activeSession);
    this.applyActiveWorkout(session);
    this.route = AppRoute.Workout;
  }

  private async finishActiveWorkout(): Promise<void> {
    if (this.workoutRepository === undefined || this.activeSession === undefined) {
      return;
    }
    const finished: WorkoutSession = this.activeSession;
    await this.workoutRepository.finishWorkout(finished);
    if (finished.sourceType === 'program' && this.programRepository !== undefined) {
      await this.programRepository.advanceAfterCompletion(finished.programWorkoutId);
      await this.loadActiveProgram();
    }
    const programState = await this.workoutRepository.getProgramState();
    this.weeklyCompleted = programState.weeklyCompleted;
    this.nextWorkoutCode = programState.nextWorkoutCode;
    this.progressHighlights = await this.workoutRepository.getProgressHighlights(finished);
    this.completedSession = finished;
    this.applyActiveWorkout(undefined);
    await this.loadHistory();
    this.route = AppRoute.WorkoutComplete;
  }

  private async abandonActiveWorkout(): Promise<void> {
    if (this.workoutRepository === undefined || this.activeSession === undefined) {
      return;
    }
    await this.workoutRepository.abandonWorkout(this.activeSession.id);
    this.applyActiveWorkout(undefined);
    this.route = AppRoute.TrainingHome;
  }

  private async loadHistory(): Promise<void> {
    if (this.workoutRepository !== undefined) {
      this.historySessions = await this.workoutRepository.getHistory();
    }
  }

  private findHistorySession(id: number): WorkoutSession {
    const found: WorkoutSession | undefined = this.historySessions.find(
      (session: WorkoutSession) => session.id === id
    );
    if (found !== undefined) {
      return found;
    }
    return new WorkoutSession(0, '', '', '', WorkoutStatus.Active, WorkoutPhase.Complete, 0, 0);
  }

  private selectTab(tab: string): void {
    if (tab === 'today') {
      this.refreshDashboard();
      this.route = AppRoute.Dashboard;
      return;
    }
    if (tab === 'progress') {
      this.refreshDashboard();
      this.loadHistory();
      this.route = AppRoute.Progress;
      return;
    }
    if (tab === 'profile') {
      this.route = AppRoute.Profile;
      return;
    }
    this.route = AppRoute.TrainingHome;
  }

  private goBack(): void {
    if (this.route === AppRoute.ExerciseDetail) {
      this.detailExerciseId = '';
      this.route = AppRoute.ExerciseLibrary;
      return;
    }
    if (this.route === AppRoute.ExerciseLibrary) {
      this.route = this.libraryFromTab ? AppRoute.TrainingHome : AppRoute.CustomBody;
      this.libraryFromTab = false;
    }
  }

  private selectLibraryPart(id: string): void {
    this.libraryPartId = id;
    this.libraryEquipment = '全部';
  }

  private openExerciseDetail(id: string): void {
    this.detailExerciseId = id;
    this.route = AppRoute.ExerciseDetail;
  }

  private addDetailExercise(): void {
    if (this.detailExerciseId === '' || this.selectedExerciseIds.includes(this.detailExerciseId)) {
      return;
    }
    this.selectedExerciseIds = [...this.selectedExerciseIds, this.detailExerciseId];
    this.planItems = [...this.planItems, new PlanItem(this.detailExerciseId)];
  }

  build() {
    Column() {
      if (this.route === AppRoute.Loading) {
        Column({ space: 12 }) {
          Text('动谱')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
          Text('正在准备你的训练…')
            .fontSize(14)
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .layoutWeight(1)
      } else if (this.route === AppRoute.Onboarding) {
        OnboardingPage({
          isSaving: this.isSaving,
          onStart: (draft: OnboardingDraft) => this.completeOnboarding(draft)
        })
      } else if (this.route === AppRoute.Dashboard) {
        DashboardPage({
          viewModel: this.dashboard,
          onResumeWorkout: () => this.openActiveWorkout(),
          onOpenTraining: () => this.openRequiredPreview(),
          onOpenNutrition: () => this.openNutrition(),
          onRecordBody: () => this.route = AppRoute.BodyQuickEntry
        })
        BottomNav({ selectedTab: 'today', onSelect: (tab: string) => this.selectTab(tab) })
      } else if (this.route === AppRoute.Nutrition) {
        NutritionPage({
          summary: this.nutritionSummary,
          entries: this.nutritionEntries,
          quickFoods: this.nutritionQuickFoods,
          targetCalories: this.dashboard.goal?.targetCalories ?? 0,
          targetProteinG: this.dashboard.goal?.targetProteinG ?? 0,
          isSaving: this.isSaving,
          onBack: () => this.route = AppRoute.Dashboard,
          onQuickAdd: (quickFoodId: number) => this.addQuickFood(quickFoodId),
          onOpenEditor: () => this.route = AppRoute.FoodEntryEditor
        })
      } else if (this.route === AppRoute.FoodEntryEditor) {
        FoodEntryEditorPage({
          isSaving: this.isSaving,
          onBack: () => this.route = AppRoute.Nutrition,
          onSave: (entry: FoodEntry) => this.saveFoodEntry(entry)
        })
      } else if (this.route === AppRoute.Progress) {
        ProgressPage({
          trend: this.dashboard.weightTrend,
          nutrition: this.dashboard.nutrition,
          sessions: this.historySessions,
          weeklyCompleted: this.weeklyCompleted,
          weeklyFrequency: this.weeklyFrequency,
          onBack: () => this.route = AppRoute.Dashboard
        })
        BottomNav({ selectedTab: 'progress', onSelect: (tab: string) => this.selectTab(tab) })
      } else if (this.route === AppRoute.BodyQuickEntry) {
        BodyQuickEntryPage({
          isSaving: this.isSaving,
          onBack: () => this.route = AppRoute.Dashboard,
          onSave: (measurement: BodyMeasurement) => this.saveBodyMeasurement(measurement)
        })
      } else if (this.route === AppRoute.TrainingHome) {
        TrainingHomePage({
          weeklyFrequency: this.weeklyFrequency,
          weeklyCompleted: this.weeklyCompleted,
          workout: this.currentWorkout(),
          programName: this.programName,
          programWeek: this.programWeek,
          programWorkouts: this.programWorkouts,
          nextRequiredWorkoutIndex: this.nextRequiredWorkoutIndex,
          hasActiveWorkout: this.hasActiveWorkout,
          activeWorkoutCode: this.activeSession?.workoutCode ?? '',
          activeWorkoutName: this.activeSession?.workoutNameSnapshot ?? '',
          activeCompletedExercises: this.activeCompletedExercises,
          activeMinutes: this.activeMinutes,
          hasSavedPlan: this.customPlanSaved,
          savedPlanActionCount: this.savedPlanItems.length,
          savedPlanMinutes: Math.max(20, this.savedPlanItems.length * 7),
          savedPlanSummary: this.savedPlanItems.slice(0, 3).map((item: PlanItem) => {
            const ex: Exercise = findExercise(this.exercises, item.exerciseId);
            return ex.name;
          }).join(' · ') + (this.planItems.length > 3 ? ' · …' : ''),
          onStartRecommended: () => this.openRequiredPreview(),
          onOpenProgramWorkout: (code: string) => this.openProgramPreview(code),
          onResumeWorkout: () => this.openActiveWorkout(),
          onStartCustom: () => this.route = AppRoute.CustomBody,
          onStartSavedPlan: () => this.route = AppRoute.TrainingReady,
          onOpenSettings: () => this.route = AppRoute.Settings,
          onOpenHistory: () => {
            this.loadHistory();
            this.route = AppRoute.History;
          }
        })
        BottomNav({ selectedTab: 'training', onSelect: (tab: string) => this.selectTab(tab) })
      } else if (this.route === AppRoute.WorkoutPreview) {
        WorkoutPreviewPage({
          workout: this.previewWorkout(),
          isStarting: this.isSaving,
          onBack: () => this.route = AppRoute.TrainingHome,
          onStart: () => this.startRecommendedWorkout()
        })
      } else if (this.route === AppRoute.Settings || this.route === AppRoute.Profile) {
        SettingsPage({
          title: this.route === AppRoute.Profile ? '我的' : '设置',
          weeklyFrequency: this.weeklyFrequency,
          weightUnit: this.weightUnit,
          targetCalories: this.activeGoal.targetCalories,
          targetProteinG: this.activeGoal.targetProteinG,
          targetSteps: this.activeGoal.targetSteps,
          trainingLocation: this.activeGoal.trainingLocation,
          dedicatedLegDay: this.activeGoal.dedicatedLegDay,
          preferMachines: this.activeGoal.preferMachines,
          isSaving: this.isSaving,
          onBack: () => this.route = AppRoute.Dashboard,
          onChangeFrequency: (frequency: number) => this.changeWeeklyFrequency(frequency),
          onChangeWeightUnit: (unit: string) => this.changeWeightUnit(unit),
          onSaveTargets: (calories: number, proteinG: number, steps: number) =>
            this.saveGoalTargets(calories, proteinG, steps),
          onChangeTrainingPreference: (location: string, dedicatedLegDay: boolean, preferMachines: boolean) =>
            this.changeTrainingPreference(location, dedicatedLegDay, preferMachines)
        })
        if (this.route === AppRoute.Profile) {
          BottomNav({ selectedTab: 'profile', onSelect: (tab: string) => this.selectTab(tab) })
        }
      } else if (this.route === AppRoute.Workout && this.activeSession !== undefined) {
        WorkoutPage({
          exercise: this.currentActiveExercise(),
          exerciseIndex: this.activeSession.currentExerciseIndex,
          totalExercises: this.activeSession.exercises.length,
          errorText: this.operationError,
          isSaving: this.isSaving,
          weightUnit: this.weightUnit,
          allExercises: this.exercises,
          onLeave: () => this.route = AppRoute.ExitWorkout,
          onOpenAlternatives: () => this.route = AppRoute.ExerciseAlternatives,
          onCompleteSet: (weight: number, reps: number) => this.completeActiveSet(
            this.weightUnit === 'lb' ? weight / 2.2046226218 : weight, reps
          )
        })
      } else if (this.route === AppRoute.ExitWorkout && this.activeSession !== undefined) {
        ExitWorkoutPage({
          onReturnHome: () => this.route = AppRoute.TrainingHome,
          onContinue: () => this.openActiveWorkout(),
          onAbandon: () => this.abandonActiveWorkout()
        })
      } else if (this.route === AppRoute.ExerciseAlternatives && this.activeSession !== undefined) {
        ExerciseAlternativePage({
          alternatives: this.alternatives(),
          canReplace: this.currentActiveExercise().completedSets === 0,
          onReplace: (exerciseId: string) => this.replaceActiveExercise(exerciseId),
          onMoveToEnd: () => this.moveActiveExerciseToEnd(),
          onCancel: () => this.route = AppRoute.Workout
        })
      } else if (this.route === AppRoute.Rest && this.activeSession !== undefined) {
        RestPage({
          exercise: this.currentActiveExercise(),
          restEndAt: this.activeSession.restEndAt,
          allExercises: this.exercises,
          onAdjust: (deltaSeconds: number) => this.adjustActiveRest(deltaSeconds),
          onFinish: () => this.finishActiveRest()
        })
      } else if (this.route === AppRoute.ExerciseCompleted && this.activeSession !== undefined) {
        ExerciseCompletedPage({
          completedExercise: this.currentActiveExercise(),
          nextExercise: this.activeSession.exercises[this.activeSession.currentExerciseIndex + 1],
          allExercises: this.exercises,
          onStartNext: () => this.startNextActiveExercise()
        })
      } else if (this.route === AppRoute.WorkoutComplete && this.completedSession !== undefined) {
        WorkoutCompletePage({
          workoutCode: this.completedSession.workoutCode,
          workoutName: this.completedSession.workoutNameSnapshot,
          minutes: this.completedMinutes(),
          exerciseCount: this.completedSession.exercises.length,
          setCount: this.completedSetCount(),
          weeklyCompleted: this.weeklyCompleted,
          weeklyFrequency: this.weeklyFrequency,
          weightUnit: this.weightUnit,
          progressHighlights: this.progressHighlights,
          onDone: () => this.route = AppRoute.Dashboard
        })
      } else if (this.route === AppRoute.History) {
        HistoryPage({
          sessions: this.historySessions,
          weeklyCompleted: this.weeklyCompleted,
          weeklyFrequency: this.weeklyFrequency,
          onOpenDetail: (sessionId: number) => {
            this.detailSessionId = sessionId;
            this.route = AppRoute.HistoryDetail;
          }
        })
        BottomNav({ selectedTab: 'progress', onSelect: (tab: string) => this.selectTab(tab) })
      } else if (this.route === AppRoute.HistoryDetail) {
        WorkoutHistoryDetailPage({
          session: this.findHistorySession(this.detailSessionId),
          weightUnit: this.weightUnit,
          onBack: () => this.route = AppRoute.History
        })
      } else if (this.route === AppRoute.CustomBody || this.route === AppRoute.CustomExercise ||
        this.route === AppRoute.CustomConfirm || this.route === AppRoute.TrainingReady) {
        CustomTrainingFlow({
          exercises: this.exercises,
          route: this.route,
          planRepository: this.planRepository,
          selectedParts: $selectedParts,
          selectedExerciseIds: $selectedExerciseIds,
          planItems: $planItems,
          customPlanSaved: $customPlanSaved,
          onStartWorkout: () => this.startCustomWorkout(),
          onStartSavedWorkout: () => this.startSavedPlanWorkout(),
          onPlanSaved: () => this.savedPlanItems = this.planItems.map((item: PlanItem) => new PlanItem(
            item.exerciseId, item.sets, item.repMin, item.repMax, item.restSeconds
          )),
          onNavigate: (route: AppRoute) => this.route = route
        })
      } else if (this.route === AppRoute.ExerciseDetail || this.route === AppRoute.ExerciseLibrary) {
        AppHeader({
          title: this.route === AppRoute.ExerciseDetail ?
            findExercise(this.exercises, this.detailExerciseId).name : '动作',
          showBack: !(this.route === AppRoute.ExerciseLibrary && this.libraryFromTab),
          backGlyph: '‹',
          actionLabel: this.route === AppRoute.ExerciseLibrary ? '' : '',
          onBack: () => this.goBack(),
          onAction: () => {}
        })
        if (this.route === AppRoute.ExerciseDetail) {
          ExerciseDetailPage({
            exercise: findExercise(this.exercises, this.detailExerciseId),
            isSelected: this.selectedExerciseIds.includes(this.detailExerciseId),
            onAddExercise: () => this.addDetailExercise()
          })
        } else {
          ExerciseLibraryPage({
            exercises: this.exercises,
            selectedPartId: this.libraryPartId,
            selectedEquipment: this.libraryEquipment,
            onSelectPart: (id: string) => this.selectLibraryPart(id),
            onSelectEquipment: (equipment: string) => this.libraryEquipment = equipment,
            onOpenExercise: (id: string) => this.openExerciseDetail(id)
          })
        }
        if (this.route === AppRoute.ExerciseLibrary && this.libraryFromTab) {
          BottomNav({ selectedTab: 'training', onSelect: (tab: string) => this.selectTab(tab) })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(APP_COLOR_BG)
  }
}
