import { APP_COLOR_BG } from './AppTheme';
import { AppRoute } from './AppRoutes';
import { AppHeader } from '../components/AppHeader';
import { BottomNav } from '../components/BottomNav';
import { exerciseMatchesPart, findExercise, loadExercises, userPartId } from '../data/ExerciseCatalog';
import { PlanRepository } from '../data/repository/PlanRepository';
import { SettingsRepository } from '../data/repository/SettingsRepository';
import { WorkoutRepository } from '../data/repository/WorkoutRepository';
import { ProgramExercise, ProgramWorkout, recommendedWorkout } from '../domain/program/ProgramModels';
import { WorkoutExerciseRecord, WorkoutPhase, WorkoutSession, WorkoutStatus, ExerciseProgress } from '../domain/workout/WorkoutModels';
import { CustomTrainingFlow } from '../features/custom/CustomTrainingFlow';
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
import { Exercise } from '../model/Exercise';
import { PlanItem } from '../model/WorkoutData';

@Component
export struct AppRoot {
  @State exercises: Exercise[] = [];
  @State route: AppRoute = AppRoute.Loading;
  @State weeklyFrequency: number = 2;
  @State selectedFrequency: number = 2;
  @State weeklyCompleted: number = 0;
  @State nextWorkoutCode: string = 'A';
  @State weightUnit: string = 'kg';
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
  @State customPlanSaved: boolean = false;
  @State libraryFromTab: boolean = false;
  @State selectedParts: string[] = ['chest'];
  @State selectedExerciseIds: string[] = [];
  @State planItems: PlanItem[] = [];
  @State libraryPartId: string = 'chest';
  @State libraryEquipment: string = '全部';
  @State detailExerciseId: string = '';
  private settingsRepository: SettingsRepository | undefined;
  private workoutRepository: WorkoutRepository | undefined;
  private planRepository: PlanRepository | undefined;

  aboutToAppear(): void {
    const hostContext = this.getUIContext().getHostContext();
    if (hostContext !== undefined) {
      this.exercises = loadExercises(hostContext.resourceManager);
      this.settingsRepository = new SettingsRepository(hostContext);
      this.workoutRepository = new WorkoutRepository(hostContext);
      this.planRepository = new PlanRepository(hostContext);
      this.initializeApp();
    }
  }

  private async initializeApp(): Promise<void> {
    if (this.settingsRepository === undefined || this.workoutRepository === undefined) {
      return;
    }
    try {
      const settings = await this.settingsRepository.getSettings();
      const programState = await this.workoutRepository.getProgramState();
      const activeWorkout: WorkoutSession | undefined = await this.workoutRepository.getActiveWorkout();
      await this.loadCustomPlan();
      this.weeklyFrequency = settings.weeklyFrequency;
      this.selectedFrequency = settings.weeklyFrequency;
      this.weightUnit = settings.weightUnit;
      this.weeklyCompleted = programState.weeklyCompleted;
      this.nextWorkoutCode = programState.nextWorkoutCode;
      this.applyActiveWorkout(activeWorkout);
      this.route = settings.onboardingCompleted ? AppRoute.TrainingHome : AppRoute.Onboarding;
    } catch (_) {
      this.route = AppRoute.Onboarding;
    }
  }

  private async loadCustomPlan(): Promise<void> {
    if (this.planRepository === undefined) {
      return;
    }
    const plan = await this.planRepository.getLatestPlan();
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
    this.customPlanSaved = plan.status === 'saved';
  }

  private applyActiveWorkout(session: WorkoutSession | undefined): void {
    this.activeSession = session;
    this.hasActiveWorkout = session !== undefined;
    if (session === undefined) {
      this.activeCompletedExercises = 0;
      this.activeMinutes = 0;
      return;
    }
    this.nextWorkoutCode = session.workoutCode;
    this.activeCompletedExercises = session.exercises.filter((item) => item.completedSets >= item.targetSets).length;
    this.activeMinutes = Math.max(1, Math.floor((Date.now() - session.startedAt) / 60000));
  }

  private currentWorkout(): ProgramWorkout {
    return recommendedWorkout(this.nextWorkoutCode);
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
      this.route = AppRoute.TrainingHome;
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

  private async completeOnboarding(): Promise<void> {
    if (this.settingsRepository === undefined || this.isSaving) {
      return;
    }
    this.isSaving = true;
    try {
      await this.settingsRepository.completeOnboarding(this.selectedFrequency);
      this.weeklyFrequency = this.selectedFrequency;
      this.route = AppRoute.TrainingHome;
    } finally {
      this.isSaving = false;
    }
  }

  private async changeWeeklyFrequency(frequency: number): Promise<void> {
    if (this.settingsRepository === undefined) {
      return;
    }
    await this.settingsRepository.updateWeeklyFrequency(frequency);
    this.weeklyFrequency = frequency;
  }

  private async changeWeightUnit(unit: string): Promise<void> {
    if (this.settingsRepository === undefined) {
      return;
    }
    await this.settingsRepository.updateWeightUnit(unit);
    this.weightUnit = unit;
  }

  private async startRecommendedWorkout(): Promise<void> {
    if (this.workoutRepository === undefined || this.isSaving) {
      return;
    }
    this.isSaving = true;
    try {
      const session: WorkoutSession = await this.workoutRepository.startRecommendedWorkout(this.currentWorkout());
      this.applyActiveWorkout(session);
      this.openActiveWorkout();
    } finally {
      this.isSaving = false;
    }
  }

  private customWorkout(): ProgramWorkout {
    const programExercises: ProgramExercise[] = this.planItems.map((item: PlanItem) => {
      const exercise: Exercise = findExercise(this.exercises, item.exerciseId);
      return new ProgramExercise(
        exercise.id, exercise.name, userPartId(exercise), exercise.equipment, exercise.imagePath,
        item.sets, item.repMin, item.repMax, item.restSeconds
      );
    });
    return new ProgramWorkout('自定义', '自定义训练', Math.max(20, this.planItems.length * 7), programExercises);
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
      const session: WorkoutSession = await this.workoutRepository.startCustomWorkout(this.customWorkout());
      this.applyActiveWorkout(session);
      this.openActiveWorkout();
    } catch (_) {
      this.operationError = '无法开始训练，请重试';
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
    if (partName.includes('胸')) return 'chest';
    if (partName.includes('背')) return 'back';
    if (partName.includes('肩')) return 'shoulders';
    if (partName.includes('手') || partName.includes('臂')) return 'arms';
    if (partName.includes('核') || partName.includes('腰')) return 'core';
    return 'legs';
  }

  private alternatives(): Exercise[] {
    if (this.activeSession === undefined) {
      return [];
    }
    const currentId: string = this.currentActiveExercise().actualExerciseId;
    return this.exercises.filter((exercise: Exercise) =>
      exercise.id !== currentId && exerciseMatchesPart(exercise, this.alternativePartId())).slice(0, 2);
  }

  private async replaceActiveExercise(exerciseId: string): Promise<void> {
    if (this.workoutRepository === undefined || this.activeSession === undefined) {
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
    this.progressHighlights = await this.workoutRepository.getProgressHighlights(finished);
    this.completedSession = finished;
    this.weeklyCompleted += 1;
    this.nextWorkoutCode = finished.workoutCode === 'A' ? 'B' : 'A';
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
    if (tab === 'exercise') {
      this.libraryFromTab = true;
      this.route = AppRoute.ExerciseLibrary;
      return;
    }
    if (tab === 'history') {
      this.loadHistory();
      this.route = AppRoute.History;
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
          selectedFrequency: this.selectedFrequency,
          isSaving: this.isSaving,
          onSelectFrequency: (frequency: number) => this.selectedFrequency = frequency,
          onStart: () => this.completeOnboarding()
        })
      } else if (this.route === AppRoute.TrainingHome) {
        TrainingHomePage({
          weeklyFrequency: this.weeklyFrequency,
          weeklyCompleted: this.weeklyCompleted,
          workout: this.currentWorkout(),
          hasActiveWorkout: this.hasActiveWorkout,
          activeCompletedExercises: this.activeCompletedExercises,
          activeMinutes: this.activeMinutes,
          hasSavedPlan: this.customPlanSaved,
          savedPlanActionCount: this.planItems.length,
          savedPlanMinutes: Math.max(20, this.planItems.length * 7),
          savedPlanSummary: this.planItems.slice(0, 3).map((item: PlanItem) => {
            const ex: Exercise = findExercise(this.exercises, item.exerciseId);
            return ex.name;
          }).join(' · ') + (this.planItems.length > 3 ? ' · …' : ''),
          onStartRecommended: () => this.route = AppRoute.WorkoutPreview,
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
          workout: this.currentWorkout(),
          isStarting: this.isSaving,
          onBack: () => this.route = AppRoute.TrainingHome,
          onStart: () => this.startRecommendedWorkout()
        })
      } else if (this.route === AppRoute.Settings) {
        SettingsPage({
          weeklyFrequency: this.weeklyFrequency,
          weightUnit: this.weightUnit,
          onBack: () => this.route = AppRoute.TrainingHome,
          onChangeFrequency: (frequency: number) => this.changeWeeklyFrequency(frequency),
          onChangeWeightUnit: (unit: string) => this.changeWeightUnit(unit)
        })
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
          onDone: () => this.route = AppRoute.TrainingHome
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
        BottomNav({ selectedTab: 'history', onSelect: (tab: string) => this.selectTab(tab) })
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
          BottomNav({ selectedTab: 'exercise', onSelect: (tab: string) => this.selectTab(tab) })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(APP_COLOR_BG)
  }
}
